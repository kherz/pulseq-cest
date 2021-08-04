//!  BlochMcConnellSolver.h 
/*!
Class to solve the Bloch-McConnell equations for multiple pools

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

#include "SimulationParameters.h"

// !BlochMcConnellSolverBase class.
/*!
  Abstract class that can be used for generic pointers to the solver class.
*/
class BlochMcConnellSolverBase
{
public:

	BlochMcConnellSolverBase() {}
	~BlochMcConnellSolverBase() {}

	// Vitual Update function that can be called from base class pointer
	virtual void UpdateSimulationParameters(SimulationParameters &sp) {};

	//! Update Matrix with pulse info 
	virtual void UpdateBlochMatrix(SimulationParameters &sp, double rfAmplitude, double rfFrequency, double rfPhase) {};

	//! Solve Bloch McConnell equation 
	virtual void SolveBlochEquation(Eigen::VectorXd &M, double t) {};

	//! Set number of steps for pade approximation 
	virtual void SetNumStepsForPadeApprox(unsigned int nApprox) {};



};


// !BlochMcConnellSolver class.
/*!
  Template class that handles all the Bloch-McConnell equation stuff 
*/
template <int size> class BlochMcConnellSolver : public BlochMcConnellSolverBase
{
public:
	typedef Eigen::Matrix<double, size, 1> VectorNd; // typedef for Magnetization Vector
	typedef Eigen::Matrix<double, size, size> MatrixNd; // typedef for Bloch Matrix

	//! Constructor
	BlochMcConnellSolver(SimulationParameters &sp);

	//! Destructor
	~BlochMcConnellSolver();

	//! Update Matrix with tissue and scanner infos
	void UpdateSimulationParameters(SimulationParameters &sp);

	//! Update Matrix with pulse info 
	void UpdateBlochMatrix(SimulationParameters &sp, double rfAmplitude, double rfFrequency, double rfPhase);

	//! Solve Bloch McConnell equation 
	void SolveBlochEquation(Eigen::VectorXd &M, double t);

	//! Set number of steps for pade approximation 
	void SetNumStepsForPadeApprox(unsigned int nApprox);


private:
	Eigen::Matrix<double, size, size> A;               /*!< Matrix containing pool and pulse paramters   */
	Eigen::Matrix<double, size, 1> C;               /*!< Vector containing pool relaxation parameters */
	unsigned int N;           /*!< Number of CEST pools */
	unsigned int numApprox;   /*!< number of steps for pade approximation       */
	double w0;                /*!< scanner larmor frequency [rad]                  */
	double dw0;               /*!< scanner inhomogeneity [rad]                  */

};


// Template class function definitions go in header file

//! Constructor
/*!
	Sets fixed parameters such as fraction, exchange rate etc.
	\param sp SimulationParamter object containing pool informations
*/
template<int size> BlochMcConnellSolver<size>::BlochMcConnellSolver(SimulationParameters &sp)
{
	// fill A matrix with constant pool exchange and concentration parameters ////
	if (size == Eigen::Dynamic)
	{
		A.resize(sp.GetInitialMagnetizationVector()->rows(), sp.GetInitialMagnetizationVector()->rows()); // allocate space for dynamic matrices
	}

	// Get number of CEST pools for matrix size
	N = sp.GetNumberOfCESTPools();

	// set steps for pade approximation
	numApprox = 6;

	this->UpdateSimulationParameters(sp);
}

//! Desctuctor
template<int size> BlochMcConnellSolver<size>::~BlochMcConnellSolver() {} 

//! Update Matrix with tissue and scanner info 
/*!
	\param sp SimulationParamter object containing pool informations
*/
template<int size> void BlochMcConnellSolver<size>::UpdateSimulationParameters(SimulationParameters &sp)
{
	A.setConstant(0.0); // init A

	// MT
	double k_ac = 0.0; // init with 0 for late
	if (sp.IsMTActive())
	{
		double k_ca = sp.GetMTPool()->GetExchangeRateInHz();
		k_ac = k_ca * sp.GetMTPool()->GetFraction();
		A(2 * (N + 1), 3 * (N + 1)) = k_ca;
		A(3 * (N + 1), 2 * (N + 1)) = k_ac;
	}

	//WATER
	double k1a = sp.GetWaterPool()->GetR1() + k_ac;
	double k2a = sp.GetWaterPool()->GetR2();
	for (int i = 0; i < N; i++)
	{
		double k_ai = sp.GetCESTPool(i)->GetFraction() * sp.GetCESTPool(i)->GetExchangeRateInHz();
		k1a += k_ai;
		k2a += k_ai;
	}
	A(0, 0) = -k2a;
	A(1 + N, 1 + N) = -k2a;
	A(2 + 2 * N, 2 + 2 * N) = -k1a;

	//CEST POOLS
	for (int i = 0; i < N; i++)
	{
		double k_ia = sp.GetCESTPool(i)->GetExchangeRateInHz();
		double k_ai = sp.GetCESTPool(i)->GetFraction() * sp.GetCESTPool(i)->GetExchangeRateInHz();
		double k1i = sp.GetCESTPool(i)->GetR1() + k_ia;
		double k2i = sp.GetCESTPool(i)->GetR2() + k_ia;
		;
		// 1st submatrix
		A(0, i + 1) = k_ia;
		A(i + 1, 0) = k_ai;
		A(i + 1, i + 1) = -k2i;

		// 2nd Submatrix
		A(1 + N, i + 2 + N) = k_ia;
		A(i + 2 + N, 1 + N) = k_ai;
		A(i + 2 + N, i + 2 + N) = -k2i;

		//3rd submatrix
		A(2 * (N + 1), i + 1 + 2 * (N + 1)) = k_ia;
		A(i + 1 + 2 * (N + 1), 2 * (N + 1)) = k_ai;
		A(i + 1 + 2 * (N + 1), i + 1 + 2 * (N + 1)) = -k1i;
	}

	// Fill relaxation vector ////
	if (size == Eigen::Dynamic) { // alocate space for dynamic matrices
		C.resize(sp.GetInitialMagnetizationVector()->rows());
	}

	// set entries
	C.setConstant(0.0);
	C((N + 1) * 2) = sp.GetWaterPool()->GetFraction() * sp.GetWaterPool()->GetR1(); // water
	for (int i = 0; i < N; i++) { // vest
		C((N + 1) * 2 + (i + 1)) = sp.GetCESTPool(i)->GetFraction()*sp.GetCESTPool(i)->GetR1();
	}

	if (sp.IsMTActive()) { // set MT related info
		C(3 * (N + 1)) = sp.GetMTPool()->GetFraction()*sp.GetMTPool()->GetR1();
	}

	// set inhomogeneity
	w0 = sp.GetScannerB0()*sp.GetScannerGamma();
	dw0 = w0 * sp.GetScannerB0Inhom();
}

//! Update Matrix with pulse info 
/*!
	\param sp SimulationParamter object containing pool informations
	\param rfAmplitude B1 amplitude [Hz]
	\param rfFrequency B1 frequency offset from f0 [Hz]
	\param rfPhase B1 phase offset [rad]
*/
template<int size> void BlochMcConnellSolver<size>::UpdateBlochMatrix(SimulationParameters &sp, double rfAmplitude, double rfFrequency, double rfPhase)
{
	A(0, 1 + N) = dw0; // dephasing of water pool
	A(1 + N, 0) = -dw0;

	// set omega 1
	double rfAmplitude2pi = rfAmplitude*TWO_PI*sp.GetScannerRelB1();
	double rfAmplitude2piCosPhi = rfAmplitude2pi * cos(rfPhase);
	double rfAmplitude2piSinPhi = rfAmplitude2pi * sin(rfPhase);

	//water
	A(0, 2 * (N + 1)) = -rfAmplitude2piSinPhi;
	A(2 * (N + 1), 0) = rfAmplitude2piSinPhi;

	A(N + 1, 2 * (N + 1)) = rfAmplitude2piCosPhi;
	A(2 * (N + 1), N + 1) = -rfAmplitude2piCosPhi;

	//CEST 
	for (int i = 1; i <= N; i++)
	{
		A(i, i + 2 * (N + 1)) = -rfAmplitude2piSinPhi;
		A(i + 2 * (N + 1), i) = rfAmplitude2piSinPhi;

		A(N + 1 + i, i + 2 * (N + 1)) = rfAmplitude2piCosPhi;
		A(i + 2 * (N + 1), N + 1 + i) = -rfAmplitude2piCosPhi;
	}

	// set off-resonance terms
	//water
	double rfFreqOffset2pi = rfFrequency *TWO_PI;
	A(0, 1 + N) += rfFreqOffset2pi;
	A(1 + N, 0) -= rfFreqOffset2pi;
	//cest
	for (int i = 1; i <= N; i++)
	{
		double dwi = sp.GetCESTPool(i - 1)->GetShiftinPPM()*w0 - (rfFreqOffset2pi + dw0);
		A(i, i + N + 1) = -dwi;
		A(i + N + 1, i) = dwi;
	}

	//set MT term
	if (sp.IsMTActive()) {
		A(3 * (N + 1), 3 * (N + 1)) = -sp.GetMTPool()->GetR1() - sp.GetMTPool()->GetExchangeRateInHz() - pow(rfAmplitude2pi, 2)* sp.GetMTPool()->GetMTLineAtCurrentOffset(rfFreqOffset2pi + dw0, w0);
	}
}

//! Solve Bloch McConnell equation 
/*!
	\param M SimulationParamter VectorNd for which the equation should be solved
	\param t timestep for which the equation should be solved
*/
template<int size> void BlochMcConnellSolver<size>::SolveBlochEquation(Eigen::VectorXd &M, double t)
{
	VectorNd AInvT = A.inverse()*C; // helper variable A^-1 * C
	MatrixNd At = A * t;			// helper variable A * t
	//solve exponential with pade method
	int infExp; //infinity exponent of the matrix
	int j;
	std::frexp(At.template lpNorm<Eigen::Infinity>(), &infExp); // pade method is only stable if ||A||inf / 2^j <= 0.5
	j = std::max(0, infExp + 1);
	At = At * (1.0 / (pow(2, j)));
	//the algorithm usually starts with D = X = N = Identity and c = 1
	// since c is alway 0.5 after the first loop, we can start in the second round and init the matrices corresponding to that
	MatrixNd X(At); // X = A after first loop
	double c = 0.5; // c = 0.5 after first loop
	MatrixNd N(At);
	N.setIdentity();
	MatrixNd D = N - c * At;
	N += c * At;
	bool p = true; // D +- cX is dependent from (-1)^k, fastest way is with changing boolean in the loop
	double q = numApprox;
	MatrixNd cX; // helper variable for c * X
	// run the approximation
	for (int k = 2; k <= q; k++)
	{
		c *= (q - k + 1) / (k*(2 * q - k + 1));
		X = At * X;
		cX = c * X;
		N += cX;
		p ? D += cX : D -= cX;
		p = !p;
	}
	MatrixNd F = D.inverse()*N; // solve D*F = N for F
	for (int k = 1; k <= j; k++)
	{
		F *= F;
	}
	M = F * (M + AInvT) - AInvT;
}


//! Set number of steps for pade approximation 
/*!
	\param nApprox Number of approximations (default = 6)
*/
template<int size> void BlochMcConnellSolver<size>::SetNumStepsForPadeApprox(unsigned int nApprox)
{
	numApprox = nApprox;
}