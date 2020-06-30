//!  SimulationParameters.h
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

#pragma once

#include "ExternalSequence.h"
#include "Eigen/Eigen"
using namespace Eigen;

#define _USE_MATH_DEFINES
#include <cmath>
#ifndef M_PI // should be in cmath
#define M_PI 3.14159265358979323846
#endif // !M_PI

//! Scanner related info
struct Scanner
{
	double B0;                /*!< static field [T]*/
	double relB1;             /*!< relative B1 (adapt for B1 inhomogeneity simulation) */
	double B0Inhomogeneity;   /*!< field inhomogeneity [ppm] */
	double Gamma;             /*!< gyromagnetic ratio [rad/uT] */
};


//! Shape of the magnetization transfer pool
enum MTLineshape
{
	SuperLorentzian,
	Lorentzian,
	None
};

//!  Water Pool class. 
/*!
  Class containing  relaxation parameters and fraction of Pools
*/
class WaterPool
{
public:
	//! Default Constructor
	WaterPool();

	//! Constructor
	WaterPool(double nR1, double nR2, double nf);

	//! Default destructor
	~WaterPool();

	//! Get R1
	const double GetR1();

	//! Get R2
	const double GetR2();

	//! Get f
	const double GetFraction();

	//! Set R1
	void SetR1(double nR1);

	//! Set R2
	void SetR2(double nR2);

	//! Set f
	void SetFraction(double nf);


protected:
	double R1; /*!< 1/T1 [Hz]  */
	double R2; /*!< 1/T1 [Hz]  */
	double f; /*!< proton fraction  */
};

//!  CEST Pool class. 
/*!
  Class containing relaxation parameters and fraction of Pools
  and an additional chemical shift and an exchange rate
*/
class CESTPool : public WaterPool
{
public:

	//! Default Constructor
	CESTPool();

	//! Constructor
	CESTPool(double nR1, double nR2, double nf, double ndw, double nk);

	//! Copy Constructor
	CESTPool(CESTPool* c);

	//! Default destructor
	~CESTPool();

	//! Get chemical shift
	const double GetShiftinPPM();

	//! Get exchange rate
	const double GetExchangeRateInHz();

	//! Set shift
	void SetShiftinPPM(double ndw);

	//! Set exchange rate
	void SetExchangeRateInHz(double nk);

protected:
	double dw; /*!< Offset from Water resonance [ppm] */
	double k;  /*!< Exchange rate [Hz] */
};


//!  MT Pool class. 
/*!
  Class containing relaxation parameters and fraction of Pools
  and an additional chemical shift and an exchange rate
  and an additional lineshape
*/
class MTPool : public CESTPool
{
public:

	//! Default Constructor
	MTPool();

	//! Constructor
	MTPool(double nR1, double nR2, double nf, double ndw, double nk, MTLineshape nls);

	//! Default destructor
	~MTPool();

	//! Get the lineshape
	MTLineshape GetMTLineShape();

	//! Set the lineshape
	void SetMTLineShape(MTLineshape nls);

	//! Get the MT parameter at the current offset
	double GetMTLineAtCurrentOffset(double offset, double omega0);

private:

	//! Calculate the SuperLorentzian Lineshape
	double InterpolateSuperLorentzianShape(double dw);

	//! Spline interpolation to avoid pol in superlorentzian lineshape function
	double CubicHermiteSplineInterpolation(double px_int, std::vector<double> px, std::vector<double> py);

	MTLineshape ls; /*!< MT lineshape */
};



//!  SimulationParameters class. 
/*!
	Container for all the relevant simulation parameters
*/
class SimulationParameters
{
public: // TODO: write get and set methods for member variables and make them private

	//! Constructor
	SimulationParameters();
	
	//! Destructor
	~SimulationParameters();

	//! Set external sequence object
	void SetExternalSequence(ExternalSequence seq);

	//! Get external sequence object
	ExternalSequence* GetExternalSequence();

	//! Init Magnetitazion Vector Array
	void InitMagnetizationVectors(VectorXd &M, unsigned int numOutput);

	//! Get Magnetization vectors
	MatrixXd* GetMagnetizationVectors();

	//! Set Water Pool
	void SetWaterPool(WaterPool waterPool);

	//! Get Water Pool
	WaterPool* GetWaterPool();

	//! Init CEST pools
	void InitCESTPoolMemory(unsigned int numPools);

	//! Set CEST Pool
	void SetCESTPool(CESTPool cp, unsigned int poolIdx);

	//! Get CEST Pool
	CESTPool* GetCESTPool(unsigned int poolIdx);

	//! Set MT Pool
	void SetMTPool(MTPool cp);

	//! Get MT Pool
	MTPool* GetMTPool();

	//! Init Scanner variables
	void InitScanner(double b0, double b1 = 1.0, double b0Inh = 0.0, double gamma = 42.577 * 2 * M_PI);

	//! Get Scanner B0
	double GetScannerB0();

	//! Get Scanner relative B1
	double GetScannerRelB1();

	//! Get Scanner B0 inhomogeneity
	double GetScannerB0Inhom();

	//! Get Scanner Gamma
	double GetScannerGamma();

	//! Get bool if MT should be simulated
	bool IsMTActive();

	//! Get Number of CEST Pools
	unsigned int GetNumberOfCESTPools();

	//! Set Verbose mode
	void SetVerbose(bool v);

	//! Get verbose mode
	bool IsVerbose();

	//! Set Use init magnetization
	void SetUseInitMagnetization(bool initMag);

	//! Get Use init magnetization
	bool GetUseInitMagnetization();

	//! Set number of max pulse samples
	void SetMaxNumberOfPulseSamples(unsigned int numSamples);

	//! Get number of max pulse samples
	unsigned int GetMaxNumberOfPulseSamples();


	
protected:

	ExternalSequence sequence; /*!< pulseq sequence */

	MatrixXd Mvec;  /*!< Matrix containing all magnetization vectors */

	WaterPool waterPool; /*!< Water Pool */
	MTPool mtPool;       /*!< MT Pool */
	CESTPool* cestPools;  /*!< CEST Pool(s) */

	Scanner scanner;     /*!< Sruct with field related info */
	
	bool simulateMTPool;    /*!< true if MT should be simulated */

	unsigned int numberOfCESTPools; /*!< number of CEST Pools */
	bool cestMemAllocated;          /*!< true if memory for cest pools was allocated*/

	bool verboseMode;                      /*!< true, if you want to have some output information */
	bool useInitMagnetization;             /*!< true, if the magnetization vector should be reset to the initial magnetization after each adc */
	unsigned int maxNumberOfPulseSamples;  /*!< number of pulse samples for shaped pulses */

};


