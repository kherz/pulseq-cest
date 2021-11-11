//!  SimulationParameters.cpp
/*!
Container class for all simulation related parameters that need to get passed between classes and functions

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


#include "SimulationParameters.h"


// Water Pool Function Definitions ////

//! Default Constructor
WaterPool::WaterPool() : R1(0), R2(0), f(0) {}

//! Constructor
/*!
  \param nR1 R1 of water pool [1/s]
  \param nR2 R2 of water pool [1/s]
  \param nf fraction of water pool
*/
WaterPool::WaterPool(double nR1, double nR2, double nf) : R1(nR1), R2(nR2), f(nf) {}

//! Default destructor
WaterPool::~WaterPool() {}

//! Get R1
/*! \return 1/T1 of pool */
const double WaterPool::GetR1() { return R1; }

//! Get R2
/*! \return 1/T2 of pool */
const double WaterPool::GetR2() { return R2; }

//! Get f
/*! \return fraction of pool */
const double WaterPool::GetFraction() { return f; }

//! Set R1
/*! \param new 1/T1 of pool */
void WaterPool::SetR1(double nR1) { R1 = nR1; }

//! Set R2
/*! \param new 1/T2 of pool */
void WaterPool::SetR2(double nR2) { R2 = nR2; }

//! Set f
/*! \param new fraction of pool */
void WaterPool::SetFraction(double nf) { f = nf; }


// CEST Pool Function Definitions ////

//! Default Constructor
CESTPool::CESTPool() : dw(0), k(0) {}

//! Constructor
/*!
  \param nR1 R1 of CEST pool [1/s]
  \param nR2 R2 of CEST pool [1/s]
  \param nf fraction of CEST pool
  \param ndw chemical shift of CEST pool [ppm]
  \param nk exchange rate of CEST pool [Hz]
*/
CESTPool::CESTPool(double nR1, double nR2, double nf, double ndw, double nk) : WaterPool(nR1, nR2, nf), dw(ndw), k(nk) {}

//! Default destructor
CESTPool::~CESTPool() {}

//! Get chemical shift
/*! \return chemical shift of pool in ppm*/
const double CESTPool::GetShiftinPPM() { return dw; }

//! Get exchange rate
/*! \return exchage rate of pool in Hz*/
const double CESTPool::GetExchangeRateInHz() { return k; }

//! Set shift
/*! \param ndw new chemical shift of pool in ppm*/
void CESTPool::SetShiftinPPM(double ndw) { dw = ndw; }

//! Set exchange rate
/*! \param nk new exchage rate of pool in Hz*/
void CESTPool::SetExchangeRateInHz(double nk) { k = nk; }


// MT Pool Function Definitions ////

//! Default Constructor
MTPool::MTPool() : ls(None) {}

//! Constructor
/*!
  \param nR1 R1 of MT pool [1/s]
  \param nR2 R2 of MT pool [1/s]
  \param nf fraction of MT pool
  \param ndw chemical shift of MT pool [ppm]
  \param nk exchange rate of MT pool [Hz]
  \param nls lineshape of MT pool
*/
MTPool::MTPool(double nR1, double nR2, double nf, double ndw, double nk, MTLineshape nls) : CESTPool(nR1, nR2, nf, ndw, nk), ls(nls) {}

//! Default destructor
MTPool::~MTPool() {}

//! Get the lineshape
/*! \return lineshape of MT pool*/
MTLineshape MTPool::GetMTLineShape() { return ls; }

//! Set the lineshape
/*! \param nls new lineshape of MT pool*/
void MTPool::SetMTLineShape(MTLineshape nls) { ls = nls; }

//! Get the MT parameter at the current offset
/*!
	The return value considers the lineshape of the MT pool
	It's defined in doi:10.1088/0031-9155/58/22/R221 as Rrfb
	The return value is Rrfb/(w1^2)
	\param offset frequency offset of rf pulse
	\param omega0 larmor frequency
	\return Rrfb/(w1^2) of MT pool
*/
double MTPool::GetMTLineAtCurrentOffset(double offset, double omega0)
{
	double mtLine = 0.0;
	switch (ls)
	{
	case None: // 0.0 stays
	{
		break;
	}
	case Lorentzian:
	{
		double T2 = 1 / R2;
		mtLine = T2 / (1 + pow((offset - dw * omega0)*T2, 2.0));
		break;
	}
	case SuperLorentzian: // integrated SL lineshape
	{
		double dw0 = dw * omega0;
		double dwPool = (offset - dw0);
		if (abs(dwPool) >= omega0) // empirical cutoff is 1 ppm
		{
			mtLine = InterpolateSuperLorentzianShape(dwPool);
		}
		else // return lorentian lineshape if we are in a pol region
		{
			std::vector<double> px{ -300 - omega0, -100 - omega0, 100 + omega0, 300 + omega0 };
			std::vector<double> py(px.size(),0);
			for (int i = 0; i < px.size(); i++) {
				py[i] = InterpolateSuperLorentzianShape(px[i]);
			}
			mtLine = CubicHermiteSplineInterpolation(dwPool, px, py);
		}
		break;
	}
	default:
		break;
	}
	return mtLine;
}

//! Calculate the SuperLorentzian Lineshape
/*!
	\param dw frequency offset between rf pulse and offset of MT pool [rad]
	\return lineshape of MT pool
*/
double MTPool::InterpolateSuperLorentzianShape(double dw)
{
	double mtLine = 0.0;
	double T2 = 1 / R2;
	int numberOfIntegrationSamples = 101; // number of
	double integrationSampleStepSize = 0.01;
	double sqrt_2_pi = sqrt(2.0 / M_PI);
	for (int i = 0; i < numberOfIntegrationSamples; i++)
	{
		double powcu2 = abs(3.0 * pow(integrationSampleStepSize*double(i), 2.0) - 1.0); // helper variable
		mtLine += sqrt_2_pi * T2 / powcu2 * exp(-2.0 * pow(dw * T2 / powcu2, 2.0)); // add to integrate
	}
	return mtLine * (M_PI * integrationSampleStepSize); // final line
}

//! Spline interpolation to avoid pol in superlorentzian lineshape function
/*!
	\param px_int position at which the splin eposition should be calculated
	\param px vector with the x postion of the 4 grid points of the spline
	\param py vector with the y postion of the 4 grid points of the spline
	\return lineshape of MT pool, 0.0 if non-valid input
*/
double MTPool::CubicHermiteSplineInterpolation(double px_int, std::vector<double> px, std::vector<double> py)
{
	if (px.size() != 4 || py.size() != 4)
		return 0.0;

	//y values
	double p0y = py[1]; //points
	double p1y = py[2];

	double tangentWeight = 30; // empirically chosen 
	double d0y = tangentWeight * (p0y - py[0]); //tangents
	double d1y = tangentWeight * (py[3] - p1y);

	//calculate the interpolation points
	double cStep = abs((px_int - px[1] + 1.0) / (px[2] - px[1] + 1.0));//
	double c3 = cStep * cStep*cStep;
	double c2 = cStep * cStep;

	// hermite spline
	double h0 = 2 * c3 - 3 * c2 + 1;
	double h1 = -2 * c3 + 3 * (c2);
	double h2 = c3 - 2 * c2 + cStep;
	double h3 = c3 - c2;
	//calculate y value
	return h0 * p0y + h1 * p1y + h2 * d0y + h3 * d1y;
}



// Simulation Parameters Function Definitions ////

//! Constructor
SimulationParameters::SimulationParameters()
{
	simulateMTPool = false;
	verboseMode = false;
	useInitMagnetization = true;
	maxNumberOfPulseSamples = 100;
	InitScanner(0.0);
}

//! Destructor
SimulationParameters::~SimulationParameters()
{
}

//! Get Magnetization vectors
/*!	\return Magnetization vectors at each ADC event */
void SimulationParameters::SetInitialMagnetizationVector(Eigen::VectorXd magVec)
{
	M = magVec;
}

//! Get Magnetization vectors
/*!	\return Magnetization vectors at each ADC event */
Eigen::VectorXd* SimulationParameters::GetInitialMagnetizationVector()
{
	return &M;
}

//! Set Water Pool
/*!	\param wp new water pool */
void SimulationParameters::SetWaterPool(WaterPool wp)
{
	waterPool = wp;
}

//! Get Water Pool
/*!	\return pointer to water pool */
WaterPool* SimulationParameters::GetWaterPool()
{
	return &waterPool;
}


//! Set CEST Pool
/*!
	\param cp new CEST pool
	\param poolIdx id of cest pool [0 ... numberOfCESTPools-1]
*/
void  SimulationParameters::SetCESTPool(CESTPool cp, unsigned int poolIdx)
{
	if (poolIdx < cestPools.size())
		cestPools[poolIdx] = cp;
}

//! Get CEST Pool
/*!
	\param poolIdx id of cest pool [0 ... numberOfCESTPools-1]
	\return pointer to cest pool at poolIdx
*/
CESTPool* SimulationParameters::GetCESTPool(unsigned int poolIdx)
{
	return poolIdx < cestPools.size() ? &cestPools[poolIdx] : NULL;
}

//! Set MT Pool
/*!	\param mp new mt pool */
void SimulationParameters::SetMTPool(MTPool mp)
{
	mtPool = mp;
	simulateMTPool = true;
}

//! Get MT Pool
/*!	\return pointer to mt pool */
MTPool* SimulationParameters::GetMTPool()
{
	return simulateMTPool ? &mtPool : NULL;
}

//! Set Scanner related info
/*!
	\param b0 static field [T]
	\param relB1 relative B1
	\param B0Inhomogeneity field inhomogeneity [ppm]
	\param Gamma gyromagnetic ratio [rad/uT]
	\param leadtime coil lead time [s]
	\param holdtime coil hold time [s]
*/
void SimulationParameters::InitScanner(double b0, double b1, double b0Inh, double gamma)
{
	Scanner s{ b0,b1,b0Inh,gamma};
	this->InitScanner(s);
}

//! Set Scanner related info
/*!	\parem Scanner object */
void SimulationParameters::InitScanner(Scanner s)
{
	scanner = s;
}

//! Get Scanner B0
/*!	\return static field of scanner [T] */
double SimulationParameters::GetScannerB0()
{
	return scanner.B0;
}

//! Get Scanner relative B1
/*!	\return relative b1 of scanner */
double SimulationParameters::GetScannerRelB1()
{
	return scanner.relB1;
}

//! Set Scanner B1 inhomogeneity
/*!	\param b1 new B1 inhomogeneity */
void  SimulationParameters::SetScannerRelB1(double b1)
{
	scanner.relB1 = b1;
}

//! Get Scanner B0 inhomogeneity
/*!	\return field inhomogeneity [ppm] of scanner */
double SimulationParameters::GetScannerB0Inhom()
{
	return scanner.B0Inhomogeneity;
}

//! Set Scanner B0 inhomogeneity
/*!	\param db0 new B0 inhomogeneity */
void  SimulationParameters::SetScannerB0Inhom(double db0)
{
	scanner.B0Inhomogeneity = db0;
}

//! Get Scanner Gamma
/*!	\return gyromagnetic ratio of simulated nucleus [rad/uT] */
double SimulationParameters::GetScannerGamma()
{
	return scanner.Gamma;
}

//! Get bool if MT should be simulated
/*!	\return true, if an MT pool should be simulated */
bool SimulationParameters::IsMTActive()
{
	return simulateMTPool;
}

//! Set Number of CEST Pools
/*!	\param total number of CEST pools that should be simulates */
void SimulationParameters::SetNumberOfCESTPools(unsigned int nPools)
{
	cestPools.resize(nPools);
}

//! Get Number of CEST Pools
/*!	\return total number of CEST pools that should be simulates */
unsigned int SimulationParameters::GetNumberOfCESTPools()
{
	return cestPools.size();
}

//! Set Verbose mode
/*!	\param v info about verbosity (true/false) */
void SimulationParameters::SetVerbose(bool v)
{
	verboseMode = v;
}

//! Get verbose mode
/*!	\return info about verbosity (true/false) */
bool SimulationParameters::IsVerbose()
{
	return verboseMode;
}

//! Set Use init magnetization
/*!
	True, if the magnetization should be reset to the initial M vector after each ADC
	This can be set to false if the readout is simulated as well
	e.g. for MRF sequences where a transient magnetization is important
	\param initMag true if magnetizytion should be initialized after ADC
*/
void SimulationParameters::SetUseInitMagnetization(bool initMag)
{
	useInitMagnetization = initMag;
}

//! Get Use init magnetization
/*!	\return info about freshly initialized magnetization after ADC */
bool SimulationParameters::GetUseInitMagnetization()
{
	return useInitMagnetization;
}

//! Set number of max pulse samples
/*!
    pulseq samples pulses at each us. For simulation these pulses are 
	resampled to <= maxNumberOfPulseSamples (default = 100)
	\param numSamples max samples for shaped pulses
*/
void SimulationParameters::SetMaxNumberOfPulseSamples(unsigned int numSamples)
{
	maxNumberOfPulseSamples = numSamples;
}

//! Get number of max pulse samples
/*!	\return max samples of shaped pulses */
unsigned int SimulationParameters::GetMaxNumberOfPulseSamples()
{
	return maxNumberOfPulseSamples;
}

