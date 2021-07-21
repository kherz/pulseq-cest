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

#include "SimulationParameters.h"
#include "BlochMcConnellSolver.h"

#define MAX_CEST_POOLS 100

void SimPulseqSBB(SimulationParameters& sp, std::string seq_filename)
{
    ExternalSequence seq;
    seq.load(seq_filename);
    sp.SetExternalSequence(seq);

    /* For a small number of pools the matrix size can be set at compile time. This ensures allocation on the stack and
    therefore a faster simulation. This speed advantage vanishes for more pools and can even result in a stack overflow
    for very large matrices. In this case more than 3 pools are simulated with dynamic matrices.
	*/
	BlochMcConnellSolverBase* solver;
	switch (sp.GetNumberOfCESTPools())
	{
	case 0: // only water
		if (sp.IsMTActive())
			solver = new  BlochMcConnellSolver<4>(sp);
		else
			solver = new BlochMcConnellSolver<3>(sp);
		break;
	case 1: // one cest pool
		if (sp.IsMTActive())
			solver = new  BlochMcConnellSolver<7>(sp);
		else
			solver = new BlochMcConnellSolver<6>(sp);
		break;
	case 2: // two cest pools
		if (sp.IsMTActive())
			solver = new  BlochMcConnellSolver<10>(sp);
		else
			solver = new BlochMcConnellSolver<9>(sp);
		break;
	case 3: // three cest pools
		if (sp.IsMTActive())
			solver = new  BlochMcConnellSolver<13>(sp);
		else
			solver = new BlochMcConnellSolver<12>(sp);
		break;
	default:
		solver = new BlochMcConnellSolver<Eigen::Dynamic>(sp); // > three pools
		break;
	}

	// it is possible to change parameters now and update the function like this:
	// sp.SetScannerB0Inhom(1.0);
	// solver->UpdateSimulationParameters(sp);
	solver->RunSimulation(sp);

	delete solver;
}
