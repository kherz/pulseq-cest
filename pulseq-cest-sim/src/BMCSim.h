//!  BMCsim.h 
/*!
Class that handles the simulation.

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

#pragma once

#include "SimulationParameters.h"
#include "BlochMcConnellSolver.h"

//! A single pulse sample for simulation
struct PulseSample
{
	double magnitude;  /*!< pulse sample amplitude [Hz]*/
	double phase;      /*!< pulse sample phase [rad]*/
	double timestep;   /*!< pulse sample duration [rad]*/
};

//! Pulse Event sctruct that contains the parameters important for simulation
struct PulseEvent
{
	double length;                     /*!< pulse duration [us]*/
	double deadTime;                   /*!< pulse dead time [us]*/
	std::vector<PulseSample> samples;  /*!< vector with all pulse amplitude, phase and time samples*/
};

//!  BMCSim class. 
/*!
  Class that serves as a simulation framework and brings together the SimulationParameters and the ExternalSequence
*/
class BMCSim
{
public:

	// typedef for pulse id with amplitude, phase and time id
	typedef std::tuple<int, int, int> PulseID;

	//! Constructor
	BMCSim(SimulationParameters &SimPars);

	//! Destructor
	~BMCSim();

	//! Load external Pulseq sequence
	bool LoadExternalSequence(std::string path);

	//! Get unique pulse
	PulseEvent* GetUniquePulse(PulseID id);

	//! Set simulations parameters object
	bool SetSimulationParameters(SimulationParameters &SimPars);

	//! Get simulations parameters object
	SimulationParameters GetSimulationParameters();

	//! Get magnetization vector after simulation
	Eigen::MatrixXd GetMagnetizationVectors();

	//! Run Simulation
	bool RunSimulation();


private:

	ExternalSequence seq; /*!< External Pulseq sequence */
	bool sequenceLoaded; /*!< true if sequence was succesfully loaded */
	std::map<PulseID, PulseEvent>  uniquePulses; /*!< vector with unique pulse sample */
	unsigned int numberOfADCBlocks;  /*!< number of ADC blocks in external seq file */

	SimulationParameters* sp; /*!< Pointer to SimulationParameters object */

	BlochMcConnellSolverBase* solver; /*!< Templated Bloch McConnell solver  */

	Eigen::MatrixXd Mvec;  /*!< Matrix containing all magnetization vectors */

	//! Init solver
	void InitSolver();

	//! Decode the pulses in the sequence
	void DecodeSeqRFInfo();

	//! Decode the adc in the sequence
	bool DecodeSeqADCInfo();
};