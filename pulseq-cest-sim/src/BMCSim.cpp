//!  BMCsim.cpp
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


#include "BMCSim.h"

//! Constructor
/*!	\param SimPars initial SimulationParameters object */
BMCSim::BMCSim(SimulationParameters &simPars) {
	sp = &simPars;
	InitSolver();
	sequenceLoaded = false;
}

//! Destructor
BMCSim::~BMCSim() {
}

//! Load external Pulseq sequence
/*!
	\param path full filepath of the .seq-file
	\return true if sequence could be loaded and contains adc events
*/
bool BMCSim::LoadExternalSequence(std::string path)
{
	sequenceLoaded = seq.load(path);
	if (sequenceLoaded) {
		this->DecodeSeqRFInfo();
		sequenceLoaded = this->DecodeSeqADCInfo();
		if (sequenceLoaded)	{
			Mvec = sp->GetInitialMagnetizationVector()->rowwise().replicate(numberOfADCBlocks);
		}
	}
	return sequenceLoaded;
}

//! Set simulations parameters object
/*!
	\param SimPars new SimulationParameters object
	\return true if SimPars hase the same amount of pool as the initial sp
*/
bool BMCSim::SetSimulationParameters(SimulationParameters &simPars) {
	// sim parameters can only be updated if number of pools did not change
	bool newSimParamsValid = (sp->GetNumberOfCESTPools() == simPars.GetNumberOfCESTPools() && sp->IsMTActive() == simPars.IsMTActive());
	if (newSimParamsValid)
		sp = &simPars;
	return newSimParamsValid;
}

//! Get simulations parameters object
/*!	\return SimulationParameters object of the BMCSim calss sp */
SimulationParameters BMCSim::GetSimulationParameters() {
	return *sp;
}

//! Get pointer to magnetitazion vectors
/*!	\return Magnetization vector at each adc event */
Eigen::MatrixXd* BMCSim::GetMagnetizationVectors() {
	return &Mvec;
}

//! Get magnetitazion vectors
/*!	\return Magnetization vector at each adc event */
Eigen::MatrixXd BMCSim::GetCopyOfMagnetizationVectors()
{
	return Mvec;
}


//! Init the solver
void BMCSim::InitSolver() {
	switch (sp->GetNumberOfCESTPools()) {
	case 0: // only water
		if (sp->IsMTActive())
			solver = std::unique_ptr<BlochMcConnellSolver<4> >(new BlochMcConnellSolver<4>(*sp));
		else
			solver = std::unique_ptr<BlochMcConnellSolver<3> >(new BlochMcConnellSolver<3>(*sp));
		break;
	case 1: // one cest pool
		if (sp->IsMTActive())
			solver = std::unique_ptr<BlochMcConnellSolver<7> >(new BlochMcConnellSolver<7>(*sp));
		else
			solver = std::unique_ptr<BlochMcConnellSolver<6> >(new BlochMcConnellSolver<6>(*sp));
		break;
	case 2: // two cest pools
		if (sp->IsMTActive())
			solver = std::unique_ptr<BlochMcConnellSolver<10> >(new BlochMcConnellSolver<10>(*sp));
		else
			solver = std::unique_ptr<BlochMcConnellSolver<9> >(new BlochMcConnellSolver<9>(*sp));
		break;
	case 3: // three cest pools
		if (sp->IsMTActive())
			solver = std::unique_ptr<BlochMcConnellSolver<13> >(new BlochMcConnellSolver<13>(*sp));
		else
			solver = std::unique_ptr<BlochMcConnellSolver<12> >(new BlochMcConnellSolver<12>(*sp));
		break;
	default:
		solver = std::unique_ptr<BlochMcConnellSolver<Eigen::Dynamic> >(new BlochMcConnellSolver<Eigen::Dynamic>(*sp)); // > three pools
		break;
	}
}


//! Decode the unique pulses from the seq file
void BMCSim::DecodeSeqRFInfo()
{
	std::vector<PulseID> uniquePuleIDs;
	for (unsigned int nSample = 0; nSample < seq.GetNumberOfBlocks(); nSample++)
	{
		SeqBlock* seqBlock = seq.GetBlock(nSample);
		if (seqBlock->isRF())
		{
			RFEvent rf = seqBlock->GetRFEvent();
			// make unique magnitude, phase and time tuple (time is placeholder for future Pulseq 1.4 support)
			int timeID = 0;
			PulseID p = std::make_tuple(rf.magShape, rf.phaseShape, timeID);
			if (!(std::find(uniquePuleIDs.begin(), uniquePuleIDs.end(), p) != uniquePuleIDs.end())) {
				// register pulse
				PulseEvent pulse;
				// get rf and check its length
				seq.decodeBlock(seqBlock);
				unsigned int rfLength = seqBlock->GetRFLength();

				// check arrays of uncompresed shape
				std::vector<float> amplitudeArray(seqBlock->GetRFAmplitudePtr(), seqBlock->GetRFAmplitudePtr() + rfLength);
				std::vector<float> phaseArray(seqBlock->GetRFPhasePtr(), seqBlock->GetRFPhasePtr() + rfLength);
				// rfDeadTime is usually zeros at the end of the pulse, we search for them here
				int nEnd;
				int delayAfterPulse = 0;
				for (nEnd = rfLength; nEnd > 0; --nEnd) {
					if (fabs(amplitudeArray[nEnd - 1]) > 1e-6)// because of the round-up errors in the ascii and derivative/integral reconstructuion
						break;
				}
				// get ringdown time after the pulse
				delayAfterPulse = rfLength - nEnd;
				pulse.ringdownTime = double(delayAfterPulse)*1e-6;
				// set new pulse length
				rfLength = nEnd;
				pulse.length = rfLength;
				// get dead time before pulse event
				pulse.deadTime = double(seqBlock->GetRFEvent().delay)*1e-6;

				amplitudeArray.erase(amplitudeArray.end() - delayAfterPulse, amplitudeArray.end());
				phaseArray.erase(phaseArray.end() - delayAfterPulse, phaseArray.end());
				// search for unique samples in amplitude and phase
				std::vector<float> amplitudeArrayUnique(rfLength);
				std::vector<float>::iterator it_amplitude = std::unique_copy(amplitudeArray.begin(), amplitudeArray.end(), amplitudeArrayUnique.begin());
				amplitudeArrayUnique.resize(std::distance(amplitudeArrayUnique.begin(), it_amplitude));
				std::vector<float> phaseArrayUnique(rfLength);
				std::vector<float>::iterator it_phase = std::unique_copy(phaseArray.begin(), phaseArray.end(), phaseArrayUnique.begin());
				phaseArrayUnique.resize(std::distance(phaseArrayUnique.begin(), it_phase));

				// need to resample pulse
				unsigned int max_samples = std::max(amplitudeArrayUnique.size(), phaseArrayUnique.size());
				if (max_samples > sp->GetMaxNumberOfPulseSamples()) {
					int sampleFactor = ceil(float(rfLength) / sp->GetMaxNumberOfPulseSamples());
					float pulseSamples = rfLength / sampleFactor;
					float timestep = float(sampleFactor) * 1e-6;
					// resmaple the original pulse with max ssamples and run the simulation
					pulse.samples.resize(pulseSamples);
					for (int i = 0; i < pulseSamples; i++) {
						pulse.samples[i].magnitude = seqBlock->GetRFAmplitudePtr()[i*sampleFactor];
						pulse.samples[i].phase = seqBlock->GetRFPhasePtr()[i*sampleFactor];
						pulse.samples[i].timestep = timestep;
					}
				}
				else {
					std::vector<unsigned int>samplePositions(max_samples + 1);
					unsigned int sample_idx = 0;
					if (amplitudeArrayUnique.size() >= phaseArrayUnique.size()) {
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
					pulse.samples.resize(max_samples);
					samplePositions[max_samples] = rfLength;
					// now we have the duration of the single samples -> simulate it
					for (int i = 0; i < max_samples; i++) {
						pulse.samples[i].magnitude = seqBlock->GetRFAmplitudePtr()[samplePositions[i]];
						pulse.samples[i].phase = seqBlock->GetRFPhasePtr()[samplePositions[i]];
						pulse.samples[i].timestep = (samplePositions[i + 1] - samplePositions[i]) * 1e-6;
					}
				}
				uniquePuleIDs.push_back(p);
				uniquePulses.insert(std::make_pair(p, pulse));
			}
		}
		delete seqBlock;
	}
}


//! Get a unique pulse
/*!
	\param pair a pair containing the magnitude and phase id of the seq file
	\return pointer to vector containing the pulse samples of a unique pulse
*/
PulseEvent* BMCSim::GetUniquePulse(PulseID id)
{
	std::map<PulseID, PulseEvent>::iterator it;
	it = uniquePulses.find(id);
	return &(it->second);
}

//! Decode ADC info
/*!	\return true if external sequence contains ADC events */
bool BMCSim::DecodeSeqADCInfo() {
	numberOfADCBlocks = 0;
	for (unsigned int nSample = 0; nSample < seq.GetNumberOfBlocks(); nSample++) {
		SeqBlock* seqBlock = seq.GetBlock(nSample);
		if (seqBlock->isADC()) {
			numberOfADCBlocks++;
		}
		delete seqBlock; // pointer gets allocate with new in the GetBlock() function
	}
	return numberOfADCBlocks > 0 ? true : false;
}

//! Run Simulation
bool BMCSim::RunSimulation() {
	bool status = sequenceLoaded;
	if (status) {
		solver->UpdateSimulationParameters(*sp);
		unsigned int currentADC = 0;
		float accummPhase = 0; // since we simulate in reference frame, we need to take care of the accummulated phase
		// loop through event blocks
		Eigen::VectorXd M = Mvec.col(currentADC);
		for (unsigned int nSample = 0; nSample < seq.GetNumberOfBlocks(); nSample++)
		{
			// get current event block
			SeqBlock* seqBlock = seq.GetBlock(nSample);
			if (seqBlock->isADC()) {
				Mvec.col(currentADC) = M;
				if (Mvec.cols() <= ++currentADC) {
					break;
				}
				if (sp->GetUseInitMagnetization()) {
					M = Mvec.col(currentADC);
				}
			}
			else if (seqBlock->isTrapGradient(0) && seqBlock->isTrapGradient(1) && seqBlock->isTrapGradient(2)) {
				// delay for block duration
				solver->UpdateBlochMatrix(*sp, 0, 0, 0);
				solver->SolveBlochEquation(M, seqBlock->GetDuration()*1e-6);
				// kill transverse magnetization
				for (int i = 0; i < (sp->GetNumberOfCESTPools() + 1) * 2; i++)
					M[i] = 0.0;
			}
			else if (seqBlock->isRF()) { // saturation pulse
				int timeID = 0; // timeID is placeholder for future Pulseq 1.4 support
				BMCSim::PulseID p = std::make_tuple(seqBlock->GetRFEvent().magShape, seqBlock->GetRFEvent().phaseShape, timeID); // get the magnitude, phase and time tuple
				PulseEvent* pulse = this->GetUniquePulse(p); // find the unque rf id in the previously decoded seq file library
				// delay before pulse?
				if (pulse->deadTime > 0) {
					solver->UpdateBlochMatrix(*sp, 0, 0, 0);
					solver->SolveBlochEquation(M, pulse->deadTime);
				}
				// loop trough pulse samples
				std::vector<PulseSample>* pulseSamples = &(pulse->samples);
				double rfFrequency = seqBlock->GetRFEvent().freqOffset;
				for (int p = 0; p < pulseSamples->size(); p++) { // loop through pulse samples
					solver->UpdateBlochMatrix(*sp, pulseSamples->at(p).magnitude*seqBlock->GetRFEvent().amplitude, rfFrequency, -pulseSamples->at(p).phase + seqBlock->GetRFEvent().phaseOffset - accummPhase);
					solver->SolveBlochEquation(M, pulseSamples->at(p).timestep);
				}
				// delay at end of the pulse?
				if (pulse->deadTime > 0) {
					solver->UpdateBlochMatrix(*sp, 0, 0, 0);
					solver->SolveBlochEquation(M, pulse->deadTime);
				}
				int phaseDegree = pulse->length * 1e-6 * 360 * seqBlock->GetRFEvent().freqOffset;
				phaseDegree %= 360;
				accummPhase += float(phaseDegree) / 180 * PI;
			}
			else { // delay or single gradient -> simulated as delay
				float timestep = float(seqBlock->GetDuration())*1e-6;
				solver->UpdateBlochMatrix(*sp, 0, 0, 0);
				solver->SolveBlochEquation(M, timestep);
			}
			delete seqBlock; // pointer gets allocated with new in the GetBlock() function
		}
	}
	return status;
}

