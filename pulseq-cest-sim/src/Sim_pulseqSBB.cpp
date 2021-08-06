//!  Sim_pulseqSBB.cpp
/*!
MATLAB interface for Bloch-McConnell pulseq SBB simulation

kai.herz@tuebingen.mpg.de

Copyright 2020 Kai Herz

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

	if (nrhs == 0)
		mexErrMsgIdAndTxt("Sim_pulseqSBB:ReadInput", "No input found.");

	//Struct containing everything
	const mxArray* inStruct = prhs[0];

	//** Magnetization Vector **//
	if (mxGetField(inStruct, 0, "M") == NULL) {
		mexErrMsgIdAndTxt("Sim_pulseqSBB:ParseInputStruct", "No input Magnetization vector found. \nInput struct must contain an 'M' field!");
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
		mexErrMsgIdAndTxt("Sim_pulseqSBB:ParseInputStruct", "Magnetitazion vector needs to be one-dimensional");
	}

	//** Water Pool **//
	if (mxGetField(inStruct, 0, "WaterPool") == NULL) {
		mexErrMsgIdAndTxt("Sim_pulseqSBB:ParseInputStruct", "No Water Pool found. \nInput struct must contain a 'WaterPool' field!");
	}

	//water pool properties
	const mxArray* waterIdx = mxGetField(inStruct, 0, "WaterPool");
	if (mxGetField(waterIdx, 0, "R1") == NULL || mxGetField(waterIdx, 0, "R2") == NULL ||
		mxGetField(waterIdx, 0, "f") == NULL) {
		mexErrMsgIdAndTxt("Sim_pulseqSBB:ParseInputStruct", "Could not parse arguments of WaterPool. Please make sure that the struct contains R1, R2 and f");
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
			mexErrMsgIdAndTxt("Sim_pulseqSBB:ParseInputStruct", "Could not parse arguments of MTPool. Please make sure that the struct contains R1, R2, f, k, dw and Lineshape");
		}
		double* MT_R1 = mxGetPr(mxGetField(mtIdx, 0, "R1"));
		double* MT_R2 = mxGetPr(mxGetField(mtIdx, 0, "R2"));
		double* MT_f = mxGetPr(mxGetField(mtIdx, 0, "f"));
		double* MT_k = mxGetPr(mxGetField(mtIdx, 0, "k"));
		double* MT_dw = mxGetPr(mxGetField(mtIdx, 0, "dw"));
		const int cbuffer = 64;
		char tempMtls[cbuffer];
		if (mxGetString(mxGetField(mtIdx, 0, "Lineshape"), tempMtls, cbuffer) != 0) {
			mexErrMsgIdAndTxt("Sim_pulseqSBB:ParseInputStruct", "Reading lineshape failed");
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
			mexErrMsgIdAndTxt("Sim_pulseqSBB:ParseInputStruct", "No valid MT Lineshape! Use None, Lorentzian or SuperLorentzian");
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
		sp.InitCESTPoolMemory(numCESTPools);

		if (mxGetNumberOfFields(cestIdx) != 5) {
			mexErrMsgIdAndTxt("Sim_pulseqSBB:ParseInputStruct", "Could not parse arguments of CESTPool. Please make sure that the struct contains R1, R2, f, k and dw");
		}

		for (int i = 0; i < sp.GetNumberOfCESTPools(); i++) {
			double* CEST_R1 = mxGetPr(mxGetField(cestIdx, i, "R1"));
			double* CEST_R2 = mxGetPr(mxGetField(cestIdx, i, "R2"));
			double* CEST_f = mxGetPr(mxGetField(cestIdx, i, "f"));
			double* CEST_k = mxGetPr(mxGetField(cestIdx, i, "k"));
			double* CEST_dw = mxGetPr(mxGetField(cestIdx, i, "dw"));

			if (CEST_R1 == NULL || CEST_R2 == NULL || CEST_f == NULL || CEST_k == NULL || CEST_dw == NULL)
			{
				mexErrMsgIdAndTxt("Sim_pulseqSBB:ParseInputStruct", "Could not parse arguments of CESTPool. Please make sure that the struct contains R1, R2, f, k, dw and Lineshape");
			}
			sp.SetCESTPool(CESTPool(*CEST_R1, *CEST_R2, *CEST_f, *CEST_dw, *CEST_k), i);
		}
	}

	// Check if Magnetization vetor fits with number of pools
	unsigned int requiredM0Size = (sp.GetNumberOfCESTPools() + 1) * 3 + (sp.IsMTActive() ? 1 : 0);
	if (requiredM0Size != Msize) {
		mexErrMsgIdAndTxt("Sim_pulseqSBB:ParseInputStruct", "Number of Pools does not match with the M vector! Make sure M contains %i entries", requiredM0Size);
	}

	//** Scanner properties **//
	if (mxGetField(inStruct, 0, "Scanner") == NULL) {
		mexErrMsgIdAndTxt("Sim_pulseqSBB:ParseInputStruct", "No Scanner found. \nInput struct must contain a 'Scanner' field!");
	}

	const mxArray* scannerIdx = mxGetField(inStruct, 0, "Scanner");
	if (mxGetField(scannerIdx, 0, "B0") == NULL) {
		mexErrMsgIdAndTxt("Sim_pulseqSBB:ParseInputStruct", "Could not parse arguments of Scanner. Please make sure that the struct contains B0");
	}
	Scanner scanner;
	scanner.B0 = *(mxGetPr(mxGetField(scannerIdx, 0, "B0")));
	scanner.relB1 = mxGetField(scannerIdx, 0, "relB1") == NULL ? 1.0 : *(mxGetPr(mxGetField(scannerIdx, 0, "relB1")));
	scanner.B0Inhomogeneity = mxGetField(scannerIdx, 0, "B0Inhomogeneity") == NULL ? 0.0 : *(mxGetPr(mxGetField(scannerIdx, 0, "B0Inhomogeneity")));
	scanner.Gamma = mxGetField(scannerIdx, 0, "Gamma") == NULL ? 42.577 * 2 * M_PI : *(mxGetPr(mxGetField(scannerIdx, 0, "Gamma")));
	scanner.coilLeadTime = mxGetField(scannerIdx, 0, "coilLeadTime") == NULL ? 0.0 : *(mxGetPr(mxGetField(scannerIdx, 0, "coilLeadTime")));
	scanner.coilHoldTime = mxGetField(scannerIdx, 0, "coilHoldTime") == NULL ? 0.0 : *(mxGetPr(mxGetField(scannerIdx, 0, "coilHoldTime")));
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

//! Enry point for MATLAB mex function
/*!
    \param nlhs number of output arguments
	\param plhs Array of pointers to the mxArray output arguments
	\param nrhs number of input arguments
	\param prhs Array of pointers to the mxArray input arguments
*/
void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
	if (nrhs < 2) {
		mexErrMsgIdAndTxt("Sim_pulseqSBB:mexFunction:nrhs",
			"2 Inputs required, TissueProperties and Pulseq filename");
	}

	//Init sim parameters
	SimulationParameters sp;
	//init the simulation interface and read the input
	ParseInputStruct(nrhs, prhs, sp);

	// init simulation framework with simulation parameters
	BMCSim simFramework(sp);

	// disp info about input
	if (sp.IsVerbose()) {
		mexPrintf("Read parameters succesfully! \n");
		mexPrintf("Found %i CEST pool(s) and %i MT Pool(s) \n", sp.GetNumberOfCESTPools(), sp.IsMTActive() ? 1 : 0);
	}

	// get seq filename
	const int charBufferSize = 2048;
	char tmpCharBuffer[charBufferSize];
	// get filename from matlab
	mxGetString(prhs[1], tmpCharBuffer, charBufferSize);
	std::string seqFileName = std::string(tmpCharBuffer);

	// set sequence 
	if (!simFramework.LoadExternalSequence(seqFileName)) {
		mexErrMsgIdAndTxt("Sim_pulseqSBB:mexFunction", "Could not read external .seq file");
	}

	// run simulation
	if (!simFramework.RunSimulation()) {
		mexErrMsgIdAndTxt("Sim_pulseqSBB:mexFunction", "Could not run simulation. Make sure that .seq file is set.");
	}

	// return to matlab
	ReturnResultToMATLAB(plhs, &(simFramework.GetMagnetizationVectors())); // return results after simulation
}
