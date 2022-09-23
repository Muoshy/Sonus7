# Sonus7
  Sonus7 is an analog seven-band spectrum bargraph with op amps. It consists of seven VU-meters, each being fed with a bandpass filter and peak detector circuit. 
  
  Each band has a width of 1.25 octaves. The bands are: 63 Hz, 160 Hz, 400 Hz, 1.25 kHz, 2.5 kHz, 6.25 kHz, 16 kHz. 
  
  The filters are second-order Multiple Feedback bandpass filters using TLC272 opamps. The VU-meters consist of a logaritmic comparator array, also using TLC272 opamps.
  
# Features
- Fully analog
- Seven frequency bands
- 10 levels per band
- 1.25 octave bands
- 63 Hz to 16 kHz frequency range

# Filters
The filters were chosen to be Multiple Feedback filters since they allow independent adjustment of the gain $A_m$, filter quality $Q$ and mid frequency $f_m$. The transfer function and equations for calculating component values are taken from TI's design reference SLOD006B (16-31).

The gain and filter quality were set to $A_m = -10, \: Q = 6$ while capacitor values were chosen in the range of 33 to 0.33 nF to end up with reasonable resistor values. A MATLAB script is provided to calculate the exact resistor values and then round to nearest corresponding value from the E-24 series. The frequency responses are then simulated for the exact and rounded resistor values.

A final calculation is done to ensure the filters gain do not exceed the unity gain bandwidth (GBW) of the op amps. The actual amplification from the op amps is obtained from the noise gain. The noise gain is then multiplied with the corresponding mid frequency of each filter to obtain the GBW. This is also provided in the same MATLAB script. The calculation shows that all filters have a GBW below 2 MHz (TLC272), although the 16 kHz filter is close at 1.1 MHz. Thus, variations in temperature or other factors might limit the gain for 16 kHz filter.

# Comparators

# Construction

# Improvements

# Bill of Materials

# Contributors
Daniel Quach ([Muoshy](https://github.com/Muoshy))
- Filter design & Simulations
- PCB Design and assembly

Johan Wheeler ([johanwheeler](https://github.com/johanwheeler))
- Mechanical design
- Mechanical assembly