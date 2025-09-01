#!/usr/bin/env python3
#
# unbindDose.py
# Compute the upper and lower bound lunar dose from an Earth destruction impact in Grays (Gy = J/kg).
# Build: Run in PYTHON3 environment
#
# Usage:
#   python3 unbindDose.py [E=2.49e32] [eta=3e-3] [d=3.844e8] [A=0.7] [M=70.0] [f=1.0] [theta_deg=75.0] [atmos_trans=1.0]
#
# Where:
#   E = total energy (J) (default is Earth's gravitational binding energy)
#   eta = fraction of energy emitted as ionizing radiation (default 0.3%)
#   d = distance to impact (m) (default is Earth-Moon distance)
#   A = area exposed (m^2) (default 0.7 m^2, approximate human cross-section)
#   M = mass of exposed object (kg) (default 70 kg, approximate human mass)
#   f = fraction of body exposed (default 1.0, assume full exposure)
#   theta_deg = angle of lower boundary in degrees (default 75 degrees for glancing blow)
#   atmos_trans = atmospheric transmission factor (1.0 = vacuum, 0.1 = 90% attenuation)
#
# Examples:
#   python3 unbindDose.py
#   python3 unbindDose.py 1e33 0.01 3.844e8 0.7 70 1.0 60 1.0
#   python3 unbindDose.py 1.2e29 3e-3 3.844e8 0.7 70 1.0 75 0.1
#
# Notes:        
#  - Outputs dose in Grays (Gy = J/kg)
#  - Upper boundary dose assumes direct overhead exposure (max exposure)
#  - Lower boundary dose assumes angle theta_deg from vertical (glancing blow)    
#  - This is a simplified model with basic atmospheric attenuation but does not account 
#    for energy-dependent absorption, radiation type differences, secondary radiation, etc.
#  - 8 Gy is a lethal dose for humans (without medical treatment)
#  - Dose = (fluence * A * f * cos(theta)) / M
#           where fluence = (eta * E) / (4 * pi * d^2) (J/m^2) 
#  - cos(theta) = cosine of angle of incidence (1.0 for upper boundary, cos(theta_deg) for lower boundary)      
#

import sys
import math

def calc_dose(F, A, f, M, cos_theta):
    return (F * A * f * cos_theta) / M

def main():
    E   = float(sys.argv[1]) if len(sys.argv) > 1 else 2.49e32
    eta = float(sys.argv[2]) if len(sys.argv) > 2 else 3e-3
    d   = float(sys.argv[3]) if len(sys.argv) > 3 else 3.844e8
    A   = float(sys.argv[4]) if len(sys.argv) > 4 else 0.7
    M   = float(sys.argv[5]) if len(sys.argv) > 5 else 70.0
    f   = float(sys.argv[6]) if len(sys.argv) > 6 else 1.0
    theta_deg   = float(sys.argv[7]) if len(sys.argv) > 7 else 75.0
    atmos_trans = float(sys.argv[8]) if len(sys.argv) > 8 else 1.0
    cos_theta   = math.cos(theta_deg * math.pi / 180.0)
    F = eta * E / (4.0 * math.pi * d * d)
    
    F_attenuated = F * atmos_trans
    D_upper = calc_dose(F_attenuated, A, f, M, 1.0)
    D_lower = calc_dose(F_attenuated, A, f, M, cos_theta)

    print("Impact Generated Radiation Dose")
    print("-------------------------------\n")    
    print(f"fluence = {F:.6e} J/m^2")
    print()
    print(f"Dose (upper boundary, max exposure) = {D_upper:.6e} Gy")
    if (D_upper > 8):
        print("*** WARNING: Dose exceeds 8 Gy (lethal dose for humans)\n")
    print(f"Dose (lower boundary, angle {theta_deg:.1f} deg, glancing blow) = {D_lower:.6e} Gy")
    if (D_lower > 8):
        print("*** WARNING: Dose exceeds 8 Gy (lethal dose for humans)")
    print()

    return 0

if __name__ == "__main__":
    sys.exit(main())