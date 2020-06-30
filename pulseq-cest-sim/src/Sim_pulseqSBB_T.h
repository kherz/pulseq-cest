//!  Sim_pulseqSBB_T.h 
/*!
Implementation of the pulseq SBB simulation for N pools

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

#include "BlochMcConnellSolver.h"
#include <functional>
#include <numeric>
#include <vector>

//! Runs the Z-spectrum simulation
/*!
   \param sp SimulationParameters object containing pool and pulse info
*/
template <int size> void Sim_pulseqSBB_T(SimulationParameters& sp)
{

	//init solver
	BlochMcConnellSolver<size> bm_solver = BlochMcConnellSolver<size>(sp);

	unsigned int currentADC = 0;
	float accummPhase = 0; // since we simulate in reference frame, we need to take care of the accummulated phase
	// loop through event blocks
	Matrix<double, size, 1> M = sp.GetMagnetizationVectors()->col(currentADC);
	for (unsigned int nSample = 0; nSample < sp.GetExternalSequence()->GetNumberOfBlocks(); nSample++)
	{
		// get current event block
		SeqBlock* seqBlock = sp.GetExternalSequence()->GetBlock(nSample);
		if (seqBlock->isADC()) {
			sp.GetMagnetizationVectors()->col(currentADC) = M;
			if (sp.GetMagnetizationVectors()->cols() <= ++currentADC){
				break;
			}
			if (sp.GetUseInitMagnetization()) {
				M = sp.GetMagnetizationVectors()->col(currentADC);
			}
		}
		else if (seqBlock->isTrapGradient(0) && seqBlock->isTrapGradient(1) && seqBlock->isTrapGradient(2)) {
			for (int i = 0; i < (sp.GetNumberOfCESTPools()+1) * 2; i++)
				M[i] = 0.0;
		}
		else if (seqBlock->isRF())
		{
			// get rf and check its length
			sp.GetExternalSequence()->decodeBlock(seqBlock);
			unsigned int rfLength = seqBlock->GetRFLength();
			// check arrays of uncompresed shape
			std::vector<float> amplitudeArray(seqBlock->GetRFAmplitudePtr(), seqBlock->GetRFAmplitudePtr() + rfLength);
			std::vector<float> phaseArray(seqBlock->GetRFPhasePtr(), seqBlock->GetRFPhasePtr() + rfLength);
			// rfDeadTime is usually zeros at the end of the pulse, we search for them here
			int nEnd;
			int delayAfterPulse = 0;
			for (nEnd = rfLength; nEnd > 0; --nEnd)	{
				if (fabs(amplitudeArray[nEnd - 1]) > 1e-6)// because of the round-up errors in the ascii and derivative/integral reconstructuion
					break;
			}
			delayAfterPulse = rfLength - nEnd;
			rfLength = nEnd;

			amplitudeArray.erase(amplitudeArray.end() - delayAfterPulse, amplitudeArray.end());
			phaseArray.erase(phaseArray.end() - delayAfterPulse, phaseArray.end());
			// search for unique samples in amplitude and phase
			std::vector<float> amplitudeArrayUnique(rfLength);
			std::vector<float>::iterator it_amplitude = std::unique_copy(amplitudeArray.begin(), amplitudeArray.end(), amplitudeArrayUnique.begin());
			amplitudeArrayUnique.resize(std::distance(amplitudeArrayUnique.begin(), it_amplitude));
			std::vector<float> phaseArrayUnique(rfLength);
			std::vector<float>::iterator it_phase = std::unique_copy(phaseArray.begin(), phaseArray.end(), phaseArrayUnique.begin());
			phaseArrayUnique.resize(std::distance(phaseArrayUnique.begin(), it_phase));
			//
			float rfAmplitude = 0.0;
			float rfPhase = 0.0;
			float rfFrequency = seqBlock->GetRFEvent().freqOffset;
			float timestep;
			// need to resample pulse
			unsigned int max_samples = std::max(amplitudeArrayUnique.size(), phaseArrayUnique.size());
			if (max_samples > sp.GetMaxNumberOfPulseSamples()) {
				int sampleFactor = ceil(float(rfLength) / sp.GetMaxNumberOfPulseSamples());
				float pulseSamples = rfLength / sampleFactor;
				timestep = float(sampleFactor) * 1e-6;
				// resmaple the original pulse with max ssamples and run the simulation
				for (int i = 0; i < pulseSamples; i++) {
					rfAmplitude = seqBlock->GetRFAmplitudePtr()[i*sampleFactor] * seqBlock->GetRFEvent().amplitude;
					rfPhase     = seqBlock->GetRFPhasePtr()[i*sampleFactor] + seqBlock->GetRFEvent().phaseOffset;
					bm_solver.UpdateBlochMatrix(sp, rfAmplitude, rfFrequency, rfPhase-accummPhase);
					bm_solver.SolveBlochEquation(M, timestep);
				}
			}
			else {
				std::vector<unsigned int>samplePositions(max_samples+1);
				unsigned int sample_idx = 0;
				if(amplitudeArrayUnique.size() >= phaseArrayUnique.size()) {
					std::vector<float>::iterator it = amplitudeArray.begin();
					for (it_amplitude = amplitudeArrayUnique.begin(); it_amplitude != amplitudeArrayUnique.end(); ++it_amplitude) {
						it = std::find(it, amplitudeArray.end(), *it_amplitude);
						samplePositions[sample_idx++] = std::distance(amplitudeArray.begin(), it);
					}
				}
				else {
					std::vector<float>::iterator it = phaseArray.begin();
					for (it_phase = phaseArrayUnique.begin(); it_phase != phaseArrayUnique.end(); ++it_phase) {
						it = std::find(it, phaseArray.end(), *it_phase);
						samplePositions[sample_idx++] = std::distance(phaseArray.begin(), it);
					}
				}
				samplePositions[max_samples] = rfLength;
				// now we have the duration of the single samples -> simulate it
				for (int i = 0; i < max_samples; i++) {
					rfAmplitude = seqBlock->GetRFAmplitudePtr()[samplePositions[i]] * seqBlock->GetRFEvent().amplitude;
					rfPhase = seqBlock->GetRFPhasePtr()[samplePositions[i]] + seqBlock->GetRFEvent().phaseOffset;
					timestep = (samplePositions[i + 1] - samplePositions[i])*1e-6;
					bm_solver.UpdateBlochMatrix(sp, rfAmplitude, rfFrequency, rfPhase - accummPhase);
					bm_solver.SolveBlochEquation(M, timestep);
				}
			}
			// delay at end of the pulse
			if (delayAfterPulse > 0) {
				timestep = float(delayAfterPulse)*1e-6;
				bm_solver.UpdateBlochMatrix(sp, 0, 0, 0);
				bm_solver.SolveBlochEquation(M, timestep);
			}
			int phaseDegree = rfLength * 1e-6 * 360 * seqBlock->GetRFEvent().freqOffset;
			phaseDegree %= 360;
			accummPhase += float(phaseDegree)/180*PI;
		}
		else { // delay or single gradient -> simulated as delay
			float timestep = float(seqBlock->GetDuration())*1e-6;
			bm_solver.UpdateBlochMatrix(sp, 0, 0, 0);
			bm_solver.SolveBlochEquation(M, timestep);
		}
		delete seqBlock; // pointer gets allocated with new in the GetBlock() function
	}
}
