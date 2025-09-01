// unbindDose.c 
// Compute the upper and lower bound lunar dose from Earth destruction impact in Grays
// Build: gcc -O2 unbindDose.c -o unbindDose -lm
//
// Usage:
//   ./unbindDose [E=2.49e32] [eta=3e-3] [d=3.844e8] [A=0.7] [M=70.0] [f=1.0] [theta_deg=75.0] [atmos_trans=1.0]
//
// Examples:
//   ./unbindDose
//   ./unbindDose 2.49e32 3e-3 3.844e8 0.7 70 1 75
//   ./unbindDose 2.49e32 3e-3 3.844e8 0.7 70 1 75 0.1
//
// Where:
//  - E = total energy (J) released by Earth destruction
//  - eta = fraction of E emitted as radiation (3e-3 is ~nuclear explosion fraction)
//  - d = distance to Moon (m) (3.844e8 m is average Earth-Moon distance)
//  - A = fraction of radiation absorbed by body (0.7 is typical for human tissue)
//  - M = mass of body (kg) (70 kg is typical adult human mass)         
//  - f = fraction of body exposed to radiation (1.0 is full exposure)
//  - theta_deg = angle of incidence (degrees) (75 degrees is glancing blow)
//  - atmos_trans = atmospheric transmission factor (1.0 = vacuum, 0.1 = 90% attenuation)
//
// Notes:        
//  - Outputs dose in Grays (Gy = J/kg)
//  - Upper boundary dose assumes direct overhead exposure (max exposure)
//  - Lower boundary dose assumes angle theta_deg from vertical (glancing blow)   
//  - This is a simplified model with basic atmospheric attenuation but does not account 
//    for energy-dependent absorption, radiation type differences, secondary radiation, etc.
//  - 8 Gy is a lethal dose for humans (without medical treatment)
//  - M_PI is defined if not available in math.h 
//  - Dose = (fluence * A * f * cos(theta)) / M
//           where fluence = (eta * E) / (4 * pi * d^2) (J/m^2)  
//  - cos(theta) = cosine of angle of incidence (1.0 for upper boundary, cos(theta_deg) for lower boundary)      
// 

#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#ifndef M_PI
#define M_PI 3.14159265358979323846
#endif
double calc_dose(double F, double A, double f, double M, double cos_theta) {
    return (F * A * f * cos_theta) / M;
}
int main(int argc, char **argv) {
    double E   = argc>1 ? atof(argv[1]) : 2.49e32;
    double eta = argc>2 ? atof(argv[2]) : 3e-3;
    double d   = argc>3 ? atof(argv[3]) : 3.844e8;
    double A   = argc>4 ? atof(argv[4]) : 0.7;
    double M   = argc>5 ? atof(argv[5]) : 70.0;
    double f   = argc>6 ? atof(argv[6]) : 1.0;
    double theta_deg = argc>7 ? atof(argv[7]) : 75.0;
    double atmos_trans = argc>8 ? atof(argv[8]) : 1.0;

    double cos_theta = cos(theta_deg * M_PI / 180.0);
    double F = eta * E / (4.0 * M_PI * d * d);
    double F_attenuated = F * atmos_trans;
    double D_upper = calc_dose(F_attenuated, A, f, M, 1.0);
    double D_lower = calc_dose(F_attenuated, A, f, M, cos_theta);

    printf("Impact Generated Radiation Dose\n");
    printf("-------------------------------\n\n");
    printf("fluence = %.6e J/m^2\n\n", F_attenuated);
    printf("Dose (upper boundary, max exposure) = %.6e Gy\n", D_upper);
    if (D_upper>8){   
            printf("*** WARNING: Dose exceeds 8 Gy (lethal dose for humans)\n\n");
    }
    printf("Dose (lower boundary, angle %.1f deg, glancing blow) = %.6e Gy\n",
           theta_deg, D_lower);
    if (D_lower>8){   
            printf("*** WARNING: Dose exceeds 8 Gy (lethal dose for humans)\n");
    }
    printf("\n");
    
    return 0;
}