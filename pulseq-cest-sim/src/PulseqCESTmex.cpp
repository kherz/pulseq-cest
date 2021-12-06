//!  PulseqCESTmex.cpp
/*!
MATLAB interface for Bloch-McConnell pulseq cest simulation with different call modes

kai.herz@tuebingen.mpg.de

Copyright 2021 Kai Herz

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"),
to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense,
and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

#include "BMCSim.h"
#include <matrix.h>
#include <mex.h>

#define MAX_CEST_POOLS 100

// global variables 
ExternalSequence seq;
SimulationParameters sp;
std::unique_ptr<BMCSim> simFramework;

// determine how the mex function was called
enum CallMode { INIT, UPDATE, RUN, CLOSE, INVALID };

//! Simple class to handle matlab error messages in try, catch block
class MatlabError 
{
public:
	MatlabError(std::string id, std::string msg): errorID(id), errorMessage(msg) {} // Constructor
	std::string errorID;       // identifier for matlab error message
	std::string errorMessage;  // actual error message
};


//! Reads the MATLAB input
/*!
	Input should be a single struct. The function searches for all required and optional struct parameters
	\param nrhs number of input arguments
	\param prhs Array of pointers to the mxArray input arguments
	\param sp SimulationParameters object that gets filled
	\param numADCEvents number of ADC events
*/
void ParseInputStruct(int nrhs, const mxArray *prhs[], SimulationParameters &sp)
{

	if (nrhs < 2)
		throw(MatlabError("pulseqcestmex:ParseInputStruct", "No input found."));

	//Struct containing everything
	const mxArray* inStruct = prhs[1];

	//** Magnetization Vector **//
	if (mxGetField(inStruct, 0, "M") == NULL) {
		throw(MatlabError("pulseqcestmex:ParseInputStruct", "No input Magnetization vector found. \nInput struct must contain an 'M' field!"));
	}

	unsigned int MinRows, MinCols, Msize;
	const mxArray* pMin = mxGetField(inStruct, 0, "M");
	MinRows = mxGetM(pMin); //number of rows
	MinCols = mxGetN(pMin); //number of cols
	double* Min = mxGetPr(pMin);

	//First Case -> Single Vector as Input
	if (MinRows == 1 || MinCols == 1) {
		Msize = std::max(MinRows, MinCols);
		//get the vector
		Eigen::VectorXd M;
		M.resize(Msize, 1);
		for (int i = 0; i < Msize; i++) {
			M[i] = Min[i];
		}
		sp.SetInitialMagnetizationVector(M);
	}
	//error
	else {
		throw(MatlabError("pulseqcestmex:ParseInputStruct", "Magnetitazion vector needs to be one-dimensional"));
	}

	//** Water Pool **//
	if (mxGetField(inStruct, 0, "WaterPool") == NULL) {
		throw(MatlabError("pulseqcestmex:ParseInputStruct", "No Water Pool found. \nInput struct must contain a 'WaterPool' field!"));
	}

	//water pool properties
	const mxArray* waterIdx = mxGetField(inStruct, 0, "WaterPool");
	if (mxGetField(waterIdx, 0, "R1") == NULL || mxGetField(waterIdx, 0, "R2") == NULL ||
		mxGetField(waterIdx, 0, "f") == NULL) {
		throw(MatlabError("pulseqcestmex:ParseInputStruct", "Could not parse arguments of WaterPool. Please make sure that the struct contains R1, R2 and f"));
	}
	double* Water_R1 = mxGetPr(mxGetField(waterIdx, 0, "R1"));
	double* Water_R2 = mxGetPr(mxGetField(waterIdx, 0, "R2"));
	double* Water_f = mxGetPr(mxGetField(waterIdx, 0, "f"));
	sp.SetWaterPool(WaterPool(*Water_R1, *Water_R2, *Water_f));


	//** MT Pool **//
	bool simMTpool = (mxGetField(inStruct, 0, "MTPool") != NULL);
	if (simMTpool) {
		//mt pool properties
		const mxArray* mtIdx = mxGetField(inStruct, 0, "MTPool");
		if (mxGetField(mtIdx, 0, "R1") == NULL || mxGetField(mtIdx, 0, "R2") == NULL || mxGetField(mtIdx, 0, "f") == NULL ||
			mxGetField(mtIdx, 0, "k") == NULL || mxGetField(mtIdx, 0, "dw") == NULL || mxGetField(mtIdx, 0, "Lineshape") == NULL) {
			throw(MatlabError("pulseqcestmex:ParseInputStruct", "Could not parse arguments of MTPool. Please make sure that the struct contains R1, R2, f, k, dw and Lineshape"));
		}
		double* MT_R1 = mxGetPr(mxGetField(mtIdx, 0, "R1"));
		double* MT_R2 = mxGetPr(mxGetField(mtIdx, 0, "R2"));
		double* MT_f = mxGetPr(mxGetField(mtIdx, 0, "f"));
		double* MT_k = mxGetPr(mxGetField(mtIdx, 0, "k"));
		double* MT_dw = mxGetPr(mxGetField(mtIdx, 0, "dw"));
		const int cbuffer = 64;
		char tempMtls[cbuffer];
		if (mxGetString(mxGetField(mtIdx, 0, "Lineshape"), tempMtls, cbuffer) != 0) {
			throw(MatlabError("pulseqcestmex:ParseInputStruct", "Reading lineshape failed"));
		}
		std::string mtlsString = std::string(tempMtls);
		if (mtlsString.compare("Lorentzian") == 0) {
			sp.SetMTPool(MTPool(*MT_R1, *MT_R2, *MT_f, *MT_dw, *MT_k, Lorentzian));
		}
		else if (mtlsString.compare("SuperLorentzian") == 0) {
			sp.SetMTPool(MTPool(*MT_R1, *MT_R2, *MT_f, *MT_dw, *MT_k, SuperLorentzian));
		}
		else if (mtlsString.compare("None") == 0) {
			sp.SetMTPool(MTPool(*MT_R1, *MT_R2, *MT_f, *MT_dw, *MT_k, None));
		}
		else {
			throw(MatlabError("pulseqcestmex:ParseInputStruct", "No valid MT Lineshape! Use None, Lorentzian or SuperLorentzian"));
		}
	}

	//** CEST Pool **//
	if (mxGetField(inStruct, 0, "CESTPool") != NULL) {
		const mxArray* cestIdx = mxGetField(inStruct, 0, "CESTPool");
		//cest pool properties
		unsigned int numCESTPools = mxGetNumberOfElements(cestIdx);

		if (numCESTPools > MAX_CEST_POOLS) {
			mexWarnMsgTxt("Only 100 CEST pools are possible! Ignoring the rest...");
			numCESTPools = MAX_CEST_POOLS;
		}
		sp.SetNumberOfCESTPools(numCESTPools);

		for (int i = 0; i < sp.GetNumberOfCESTPools(); i++) {
			double* CEST_R1 = mxGetPr(mxGetField(cestIdx, i, "R1"));
			double* CEST_R2 = mxGetPr(mxGetField(cestIdx, i, "R2"));
			double* CEST_f = mxGetPr(mxGetField(cestIdx, i, "f"));
			double* CEST_k = mxGetPr(mxGetField(cestIdx, i, "k"));
			double* CEST_dw = mxGetPr(mxGetField(cestIdx, i, "dw"));

			if (CEST_R1 == NULL || CEST_R2 == NULL || CEST_f == NULL || CEST_k == NULL || CEST_dw == NULL)
			{
				throw(MatlabError("pulseqcestmex:ParseInputStruct", "Could not parse arguments of CESTPool. Please make sure that the struct contains R1, R2, f, k, dw and Lineshape"));
			}
			sp.SetCESTPool(CESTPool(*CEST_R1, *CEST_R2, *CEST_f, *CEST_dw, *CEST_k), i);
		}
	}

	// Check if Magnetization vetor fits with number of pools
	unsigned int requiredM0Size = (sp.GetNumberOfCESTPools() + 1) * 3 + (sp.IsMTActive() ? 1 : 0);
	if (requiredM0Size != Msize) {
		throw(MatlabError("pulseqcestmex:ParseInputStruct", "Number of Pools does not match with the M vector!"));
	}

	//** Scanner properties **//
	if (mxGetField(inStruct, 0, "Scanner") == NULL) {
		throw(MatlabError("pulseqcestmex:ParseInputStruct", "No Scanner found. \nInput struct must contain a 'Scanner' field!"));
	}

	const mxArray* scannerIdx = mxGetField(inStruct, 0, "Scanner");
	if (mxGetField(scannerIdx, 0, "B0") == NULL) {
		throw(MatlabError("pulseqcestmex:ParseInputStruct", "Could not parse arguments of Scanner. Please make sure that the struct contains B0"));
	}
	Scanner scanner;
	scanner.B0 = *(mxGetPr(mxGetField(scannerIdx, 0, "B0")));
	scanner.relB1 = mxGetField(scannerIdx, 0, "relB1") == NULL ? 1.0 : *(mxGetPr(mxGetField(scannerIdx, 0, "relB1")));
	scanner.B0Inhomogeneity = mxGetField(scannerIdx, 0, "B0Inhomogeneity") == NULL ? 0.0 : *(mxGetPr(mxGetField(scannerIdx, 0, "B0Inhomogeneity")));
	scanner.Gamma = mxGetField(scannerIdx, 0, "Gamma") == NULL ? 42.577 * 2 * M_PI : *(mxGetPr(mxGetField(scannerIdx, 0, "Gamma")));
	sp.InitScanner(scanner);

	//** Verbose mode **//
	if (mxGetField(inStruct, 0, "Verbose") != NULL)
		sp.SetVerbose(*(mxGetPr(mxGetField(inStruct, 0, "Verbose"))));

	//** Reset Magnetization Vector with initial magnetzation after each adc **//
	if (mxGetField(inStruct, 0, "ResetInitMag") != NULL)
		sp.SetUseInitMagnetization(*(mxGetPr(mxGetField(inStruct, 0, "ResetInitMag"))));

	//** Maximum number of pulse samples **//
	if (mxGetField(inStruct, 0, "MaxPulseSamples") != NULL)
		sp.SetMaxNumberOfPulseSamples(*(mxGetPr(mxGetField(inStruct, 0, "MaxPulseSamples"))));
}


//! Returns the final Magnetization vectors for each PPM sample
/*!
	\param plhs Array of pointers to the mxArray output arguments
	\param M MatrixXd containg Magnetization vectors
*/
void ReturnResultToMATLAB(mxArray *plhs[], Eigen::MatrixXd* M) {
	//prepare the output for matlab
	plhs[0] = mxCreateDoubleMatrix(M->rows(), M->cols(), mxREAL);
	double *zOut = mxGetPr(plhs[0]);
	for (int x = 0; x < M->cols(); x++) {
		for (int y = 0; y < M->rows(); y++) {
			zOut[y + M->rows()*x] = (*M)(y, x);
		}
	}
}


//! Gets the call mode for the mex function
/*!
	\param nrhs number of input arguments
	\param prhs Array of pointers to the mxArray input arguments
	\return mode CallMode value based on input string
*/
CallMode GetCallMode(int nrhs, const mxArray *prhs[])
{
	CallMode mode = INVALID;
	if (nrhs > 0)
	{
		// get string from first matlab input
		const int charBufferSize = 64;
		char tmpCharBuffer[charBufferSize];
		mxGetString(prhs[0], tmpCharBuffer, charBufferSize);
		// check string for valid options
		if (!strcmp("init", tmpCharBuffer)) {
			mode = INIT;
		}
		else if(!strcmp("run", tmpCharBuffer)){
			mode = RUN;
		}
		else if (!strcmp("update", tmpCharBuffer)) {
			mode = UPDATE;
		}
		else if (!strcmp("close", tmpCharBuffer)) {
			mode = CLOSE;
		}
	}
	return mode;
}


//!Initialize All variables
/*!
	\param nrhs number of input arguments
	\param prhs Array of pointers to the mxArray input arguments
*/
void Initialize(int nrhs, const mxArray *prhs[])
{
	// parse input
	ParseInputStruct(nrhs, prhs, sp);
	// init framework
	simFramework = std::unique_ptr<BMCSim>(new BMCSim(sp));
	// get seq filename
	const int charBufferSize = 2048;
	char tmpCharBuffer[charBufferSize];
	// get filename from matlab
	mxGetString(prhs[2], tmpCharBuffer, charBufferSize);
	std::string seqFileName = std::string(tmpCharBuffer);
	// set sequence 
	if (!simFramework->LoadExternalSequence(seqFileName)) {
		throw(MatlabError("pulseqcestmex:Initialize", "Could not read external .seq file"));
	}
}


//! Enry point for MATLAB mex function
/*!
    \param nlhs number of output arguments
	\param plhs Array of pointers to the mxArray output arguments
	\param nrhs number of input arguments
	\param prhs Array of pointers to the mxArray input arguments
*/
void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
	try
	{
		switch (GetCallMode(nrhs, prhs))
		{
		case INIT:
			mexLock(); // start with locking mex
			Initialize(nrhs, prhs);
			break;
		case UPDATE:
			ParseInputStruct(nrhs, prhs, sp);
			break;
		case RUN:
			simFramework->RunSimulation();
			ReturnResultToMATLAB(plhs, simFramework->GetMagnetizationVectors());
			break;
		case CLOSE:
			if (mexIsLocked()) {
				mexUnlock();
			}
			break;
		case INVALID:
			throw(MatlabError("pulseqcestmex:mexFunction", "Invalid call mode, no function is called"));
			break;
		default:
			throw(MatlabError("pulseqcestmex:mexFunction", "Unspecified Error"));
		}
	}
	catch (MatlabError matlabError)
	{
		if (mexIsLocked()) {
			mexUnlock();
		}
		mexErrMsgIdAndTxt(matlabError.errorID.c_str(), matlabError.errorMessage.c_str());
	}
	catch (...) // clean up if sth didn't work
	{
		if (mexIsLocked()) {
			mexUnlock();
		}	
		mexErrMsgIdAndTxt("pulseqcestmex:mexFunction", "Unspecified Error! Cleaning up...");
	}
}
