/* unbindEnergy.c
* (C) 2025 - George McGinn - MIT License
* Compute impactor size from speed, or speed from size/mass, to meet
* the selected planet's unbinding energy U, with full relativistic kinetic energy.
* Build: gcc -O2 unbindEnergy.c -o unbindEnergy -lm
*
* Usage:
*   Given speed -> required size (assume bulk density):
*     ./unbindEnergy v <speed_km_s> [rho_kg_m3=3000] [epsilon=1.0] [name] [planet] [material]
*   Given diameter -> required speed (assume bulk density):
*     ./unbindEnergy d <diameter_km> [rho_kg_m3=3000] [epsilon=1.0] [name] [planet] [material]
*   Given mass -> required speed:
*     ./unbindEnergy m <mass_kg> [epsilon=1.0] [name] [planet] [material]
*
* Examples:
*     ./unbindEnergy m 1.2e17 0.25 "1036 Ganymed" earth stony
*     ./unbindEnergy d 0.375 2000 0.25 "Apophis at 2000 kg/m^3" jupiter stony
*     ./unbindEnergy m 1e9 0.25 Oumuamua mars cometary
*     ./unbindEnergy v 30000 2000 0.25 "30,000 km/s at 2000 kg/m^3" pluto stony
*     ./unbindEnergy d 0.375 2000 0.25 "Apophis at 2000 kg/m³" earth stony
*     ./unbindEnergy d 0.375 2000 0.25 "Apophis at 2000 kg/m³" mars iron  
*     ./unbindEnergy d 1.0 7800 0.25 "Iron asteroid" venus iron
*     ./unbindEnergy d 0.1 3000 1.0 "Small asteroid" jupiter stony
*     ./unbindEnergy d 5.0 3000 0.25 "Large comet" uranus cometary
*     ./unbindEnergy d 10.0 7800 1.0 "Massive iron" neptune iron
*     ./unbindEnergy d 0.01 1000 1.0 "Tiny rock" pluto stony
*
* Where:
*  - mass_kg = mass of impactor (kg) (1e9 to 1e23 typical range)
*  - diameter_km = diameter of impactor (km) (0.1 to 1000 km typical range)
*  - speed_km_s = velocity of impactor (km/s) (must be < c = 299,792.458 km/s)
*  - rho_kg_m3 = bulk density of impactor (kg/m^3) (3000 is typical asteroid density)
*  - epsilon = coupling efficiency (dimensionless) (fraction of KE that unbinds planet)
*  - name = optional object identifier (e.g., "1036 Ganymed", "Apophis")
*  - planet = target planet (earth, mars, venus, jupiter, saturn, uranus, neptune, pluto, moon, vacuum)
*  - material = impactor material type (stony, iron, cometary)
*  - U = Planet's gravitational binding energy (varies by planet)
*  - c = speed of light (299,792,458 m/s)
*
* Notes:
*  - U varies by planet: Earth=2.49e32 J, Jupiter=2.06e36 J, Pluto=2.85e27 J, etc.
*  - epsilon is coupling efficiency (fraction of KE that actually unbinds planet).
*  - Atmospheric retention reduces effective coupling efficiency based on diameter, planet, and material
*  - Outputs both classical and relativistic speeds for reference,
*    but the relativistic result is the one to use at high energy.
*  - Compares mass to Mercury and Ceres for scale context.
*  - This model incorporates atmospheric effects and relativistic mechanics, but uses simplified assumptions for material fragmentation, energy coupling efficiency, and complex impact dynamics.
*  - cbrt() is used for cube root (C99 and later).
*  - M_PI is defined if not available in math.h
*  - Classical KE = 0.5*m*v^2
*  - Relativistic KE = (gamma-1)*m*c^2, where gamma = 1/sqrt(1-(v/c)^2)
*  - For given KE, m = U/epsilon / KE_per_mass
*  - For given m, v_classical = sqrt(2*U/epsilon/m)
*  - For given m, gamma = 1 + U/epsilon/m/c^2
*    then v_rel = c*sqrt(1-1/gamma^2)
*  - For given diameter D and density rho, m = rho * (4/3)*pi*(D/2)^3
*  - 1 km/s = 1000 m/s
*  - 1 km = 1000 m
*  - 1 AU = 1.496e11 m
*  - Mercury mass = 3.30e23 kg
*  - Ceres mass = 9.38e20 kg
*/ 

#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <string.h>

// Planet type constants for atmospheric modeling
#define PLANET_EARTH 0
#define PLANET_MARS 1
#define PLANET_VENUS 2
#define PLANET_JUPITER 3
#define PLANET_SATURN 4
#define PLANET_URANUS 5
#define PLANET_NEPTUNE 6
#define PLANET_PLUTO 7
#define PLANET_MOON 8
#define PLANET_VACUUM 9

// Material type constants
#define MATERIAL_STONY 0
#define MATERIAL_IRON 1
#define MATERIAL_COMETARY 2

// Function to get gravitational binding energy based on planet type
double get_planetary_binding_energy(int planet_type) {
    switch(planet_type) {
        case PLANET_EARTH:   return 2.49e32;  // J - Original value from code comments
        case PLANET_MARS:    return 4.87e30;  // J - Calculated from NASA data
        case PLANET_VENUS:   return 1.57e32;  // J - Calculated from NASA data
        case PLANET_JUPITER: return 2.06e36;  // J - Calculated from NASA data
        case PLANET_SATURN:  return 2.22e35;  // J - Calculated from NASA data
        case PLANET_URANUS:  return 1.19e34;  // J - Calculated from NASA data
        case PLANET_NEPTUNE: return 1.69e34;  // J - Calculated from NASA data
        case PLANET_PLUTO:   return 2.85e27;  // J - Calculated from NASA data
        case PLANET_MOON:    return 1.23e29;  // J - Moon binding energy
        case PLANET_VACUUM:  
        default:             return 2.49e32;  // J - Default to Earth
    }
}

// Atmospheric retention function
double atmospheric_retention(double diameter_km, int planet_type, int material_type) {
    // Returns fraction of kinetic energy that reaches surface
    switch(planet_type) {
        case PLANET_EARTH:
            if (material_type == MATERIAL_IRON) { // Iron - higher survival rate
                if (diameter_km < 0.01) return 0.00;      // <10m: 0% retention
                if (diameter_km < 0.03) return 0.20;      // 10-30m: 20% retention
                if (diameter_km < 0.05) return 0.50;      // 30-50m: 50% retention  
                if (diameter_km < 0.10) return 0.80;      // 50-100m: 80% retention
                if (diameter_km < 0.20) return 0.90;      // 100-200m: 90% retention
                return 0.95;                              // >200m: 95% retention
            } else if (material_type == MATERIAL_COMETARY) { // Cometary - very low survival
                if (diameter_km < 0.05) return 0.00;      // <50m: 0% retention
                if (diameter_km < 0.20) return 0.05;      // 50-200m: 5% retention
                return 0.80;                              // >200m: 80% retention
            } else { // Stony (default)
                if (diameter_km < 0.01) return 0.01;      // <10m: 1% retention
                if (diameter_km < 0.03) return 0.10;      // 10-30m: 10% retention
                if (diameter_km < 0.20) return 0.50;      // 30-200m: 50% retention
                return 0.90;                              // >200m: 90% retention
            }
            break;
            
        case PLANET_MARS:
            // Mars: minimal atmospheric protection (1.3% of Earth's density)
            if (material_type == MATERIAL_IRON) { // Iron
                if (diameter_km < 0.001) return 0.80;     // <1m: 80% retention
                return 0.95;                              // >1m: 95% retention
            } else if (material_type == MATERIAL_COMETARY) { // Cometary
                if (diameter_km < 0.01) return 0.70;      // <10m: 70% retention
                return 0.90;                              // >10m: 90% retention
            } else { // Stony
                if (diameter_km < 0.005) return 0.85;     // <5m: 85% retention
                return 0.95;                              // >5m: 95% retention
            }
            break;
            
        case PLANET_VENUS:
            // Venus: extreme atmospheric protection (53x denser than Earth)
            if (material_type == MATERIAL_IRON) { // Iron - best survival chance
                if (diameter_km < 0.10) return 0.00;      // <100m: 0% retention
                if (diameter_km < 0.50) return 0.10;      // 100-500m: 10% retention
                if (diameter_km < 1.00) return 0.50;      // 500m-1km: 50% retention
                return 0.80;                              // >1km: 80% retention
            } else if (material_type == MATERIAL_COMETARY) { // Cometary
                if (diameter_km < 1.00) return 0.00;      // <1km: 0% retention
                return 0.30;                              // >1km: 30% retention
            } else { // Stony
                if (diameter_km < 0.20) return 0.00;      // <200m: 0% retention
                if (diameter_km < 1.00) return 0.05;      // 200m-1km: 5% retention
                return 0.60;                              // >1km: 60% retention
            }
            break;
            
        case PLANET_JUPITER:
            // Jupiter: massive atmospheric protection, crushing pressures
            if (material_type == MATERIAL_IRON) { // Iron
                if (diameter_km < 1.00) return 0.00;      // <1km: 0% retention
                if (diameter_km < 10.0) return 0.01;      // 1-10km: 1% retention
                return 0.20;                              // >10km: 20% retention
            } else { // Stony/Cometary - essentially no survival
                if (diameter_km < 10.0) return 0.00;      // <10km: 0% retention
                return 0.10;                              // >10km: 10% retention
            }
            break;
            
        case PLANET_SATURN:
            // Saturn: similar to Jupiter but larger scale height allows deeper penetration
            if (material_type == MATERIAL_IRON) { // Iron
                if (diameter_km < 0.50) return 0.00;      // <500m: 0% retention
                if (diameter_km < 5.00) return 0.05;      // 500m-5km: 5% retention
                return 0.30;                              // >5km: 30% retention
            } else { // Stony/Cometary
                if (diameter_km < 5.00) return 0.00;      // <5km: 0% retention
                return 0.15;                              // >5km: 15% retention
            }
            break;
            
        case PLANET_URANUS:
            // Uranus: ice giant with thick hydrogen/helium atmosphere + ices
            if (material_type == MATERIAL_IRON) { // Iron
                if (diameter_km < 2.00) return 0.00;      // <2km: 0% retention
                if (diameter_km < 10.0) return 0.02;      // 2-10km: 2% retention
                return 0.25;                              // >10km: 25% retention
            } else { // Stony/Cometary
                if (diameter_km < 10.0) return 0.00;      // <10km: 0% retention
                return 0.15;                              // >10km: 15% retention
            }
            break;
            
        case PLANET_NEPTUNE:
            // Neptune: densest ice giant, even more protective than Uranus
            if (material_type == MATERIAL_IRON) { // Iron
                if (diameter_km < 3.00) return 0.00;      // <3km: 0% retention
                if (diameter_km < 15.0) return 0.01;      // 3-15km: 1% retention
                return 0.20;                              // >15km: 20% retention
            } else { // Stony/Cometary
                if (diameter_km < 15.0) return 0.00;      // <15km: 0% retention
                return 0.10;                              // >15km: 10% retention
            }
            break;
            
        case PLANET_PLUTO:
            // Pluto: extremely thin nitrogen atmosphere (1 Pa vs Earth's 101,325 Pa)
            if (material_type == MATERIAL_IRON) { // Iron
                if (diameter_km < 0.001) return 0.95;     // <1m: 95% retention
                return 0.99;                              // >1m: 99% retention
            } else if (material_type == MATERIAL_COMETARY) { // Cometary
                if (diameter_km < 0.01) return 0.90;      // <10m: 90% retention
                return 0.98;                              // >10m: 98% retention
            } else { // Stony
                if (diameter_km < 0.005) return 0.92;     // <5m: 92% retention
                return 0.98;                              // >5m: 98% retention
            }
            break;

        case PLANET_MOON:
            // Moon: essentially no atmosphere (3*10^-15 Pa vs Earth's 101,325 Pa)
            // Extremely thin exosphere provides virtually no protection
            if (material_type == MATERIAL_IRON) { // Iron
                if (diameter_km < 0.001) return 0.99;     // <1m: 99% retention
                return 1.00;                              // >1m: 100% retention
            } else if (material_type == MATERIAL_COMETARY) { // Cometary
                if (diameter_km < 0.001) return 0.98;     // <1m: 98% retention
                return 0.99;                              // >1m: 99% retention
            } else { // Stony
                if (diameter_km < 0.001) return 0.99;     // <1m: 99% retention
                return 1.00;                              // >1m: 100% retention
            }
            break;
            
        case PLANET_VACUUM:
        default:
            return 1.00; // No atmospheric losses
    }
}

// Helper function to get planet type from string
int get_planet_type(const char* planet_name) {
    if (!planet_name) return PLANET_EARTH; // default
    if (strcasecmp(planet_name, "earth") == 0) return PLANET_EARTH;
    if (strcasecmp(planet_name, "mars") == 0) return PLANET_MARS;
    if (strcasecmp(planet_name, "venus") == 0) return PLANET_VENUS;
    if (strcasecmp(planet_name, "jupiter") == 0) return PLANET_JUPITER;
    if (strcasecmp(planet_name, "saturn") == 0) return PLANET_SATURN;
    if (strcasecmp(planet_name, "uranus") == 0) return PLANET_URANUS;
    if (strcasecmp(planet_name, "neptune") == 0) return PLANET_NEPTUNE;
    if (strcasecmp(planet_name, "pluto") == 0) return PLANET_PLUTO;
    if (strcasecmp(planet_name, "moon") == 0) return PLANET_MOON;
    if (strcasecmp(planet_name, "vacuum") == 0) return PLANET_VACUUM;
    return PLANET_EARTH; // default to Earth if unknown
}

// Helper function to get material type from string
int get_material_type(const char* material_name) {
    if (!material_name) return MATERIAL_STONY; // default to stony
    if (strcasecmp(material_name, "iron") == 0) return MATERIAL_IRON;
    if (strcasecmp(material_name, "cometary") == 0) return MATERIAL_COMETARY;
    if (strcasecmp(material_name, "stony") == 0) return MATERIAL_STONY;
    return MATERIAL_STONY; // default to stony
}

int main(int argc, char** argv){
    const double c  = 299792458.0;             // m/s
    const double PI = 3.14159265358979323846;  // PI
    const double MERCURY_MASS = 3.30e23;       // kg
    const double CERES_MASS   = 9.38e20;       // kg

    char* object_name = NULL;
    char* planet_name = NULL;
    char* material_name = NULL;
    int has_object = 0;
    int has_atmospheric = 0;
    int planet_type = PLANET_EARTH; // default to Earth
    int material_type = MATERIAL_STONY; // default to stony
    double U; // Will be set based on planet type
    
    if (argc > 3) {
        // Check for atmospheric parameters (planet and material) at the end
        if (argc >= 6) {
            // Check if last two arguments are not numbers (planet and material)
            char* endptr1, *endptr2;
            strtod(argv[argc-2], &endptr1);
            strtod(argv[argc-1], &endptr2);
            if (*endptr1 != '\0' && *endptr2 != '\0') {
                planet_name = argv[argc-2];
                material_name = argv[argc-1];
                has_atmospheric = 1;
                
                // Check for object name before planet/material
                if (argc >= 7) {
                    char* endptr3;
                    strtod(argv[argc-3], &endptr3);
                    if (*endptr3 != '\0') {
                        object_name = argv[argc-3];
                        has_object = 1;
                    }
                }
            }
        }
        
        // If no atmospheric params, check for object name as last argument
        if (!has_atmospheric) {
            char* last_arg = argv[argc-1];
            char* endptr;
            strtod(last_arg, &endptr);
            if (*endptr != '\0') { // not a valid double, treat as name
                object_name = last_arg;
                has_object = 1;
            }
        }
    }

    // Determine planet type and set binding energy
    planet_type = get_planet_type(planet_name);
    material_type = get_material_type(material_name);
    U = get_planetary_binding_energy(planet_type);

    if (argc < 3) {
        fprintf(stderr,
            "Usage:\n"
            "  %s m <mass_kg> [epsilon=1.0] [name] [planet/body] [impactor material]\n"
            "  %s d <diameter_km> [rho_kg_m3=3000] [epsilon=1.0] [name] [planet/body] [impactor material]\n"
            "  %s v <speed_km_s> [rho_kg_m3=3000] [epsilon=1.0] [name] [planet/body] [impactor material]\n",
            argv[0], argv[0], argv[0]);
        return 1;
    }

    char mode = argv[1][0];

    if (mode=='m' || mode=='M'){
        // Input: mass -> required speed (both classical & relativistic)
        double m = atof(argv[2]);
        double eps = (argc>3 && (!has_object || argc>4)) ? atof(argv[3]) : 1.0;
        if (m <= 0.0 || eps <= 0.0) {
            fprintf(stderr,"Inputs must be positive.\n"); return 1;
        }
        
        // Estimate diameter from mass to calculate atmospheric retention
        double volume = m / 3000.0; // Assume 3000 kg/m³ density for estimation
        double D_km = 2.0 * cbrt((3.0*volume)/(4.0*PI)) / 1000.0;
        double retention = atmospheric_retention(D_km, planet_type, material_type);
        double effective_eps = eps * retention;
        
        if (has_object) printf("OBJECT : %s\n", object_name);
        if (planet_name) printf("PLANET : %s (U = %.6e J)\n", planet_name, U);
        if (material_name) printf("MATERIAL: %s (retention = %.3f)\n", material_name, retention);

        printf("INPUT  : m = %.6e kg, epsilon = %.3f\n", m, eps);
        printf("TARGET : U/epsilon_eff = %.6e J (eff. epsilon = %.3f)\n", U/effective_eps, effective_eps);
        
        double v_class = sqrt(2.0*(U/effective_eps)/m);
        double gamma = 1.0 + (U/effective_eps)/(m*c*c);
        double v_rel, beta2;
        beta2 = 1.0 - 1.0/(gamma*gamma);
        v_rel = c * sqrt(beta2<=0.0?0.0:beta2);
        
        printf("RESULT : Required speed (classical)    = %.3f km/s\n", v_class/1000.0);
        printf("         Required speed (relativistic) = %.3f km/s\n", v_rel/1000.0);
        if (v_rel >= 0.99*c) {
            printf("         NOTE: v_rel ~ c (ultra-relativistic).\n");
            printf("         CONCLUSION: %s SURVIVES - object too small to unbind planet\n", 
                planet_name ? planet_name : "TARGET");
        } else {
            printf("         CONCLUSION: %s DESTROYED at %.3f km/s impact\n", 
                planet_name ? planet_name : "TARGET", v_rel/1000.0);
        }
        return 0;
    }

    if (mode=='d' || mode=='D'){
        // Input: diameter -> required speed (both classical & relativistic)
        double D_km = atof(argv[2]);
        double rho  = (argc>3 && (!has_object || argc>4)) ? atof(argv[3]) : 3000.0;
        double eps  = (argc>4 && has_object) ? atof(argv[4]) : (argc>3 && has_object ? 1.0 : 1.0);
        if (D_km <= 0.0 || rho <= 0.0 || eps <= 0.0){
            fprintf(stderr,"Inputs must be positive.\n"); return 1;
        }
        
        // Calculate atmospheric retention based on diameter
        double retention = atmospheric_retention(D_km, planet_type, material_type);
        double effective_eps = eps * retention;
        
        if (has_object) printf("OBJECT : %s\n", object_name);
        if (planet_name) printf("PLANET : %s (U = %.6e J)\n", planet_name, U);
        if (material_name) printf("MATERIAL: %s (retention = %.3f)\n", material_name, retention);

        double D = D_km * 1000.0;
        double volume = (4.0/3.0) * PI * pow(D/2.0, 3.0);
        double m = rho * volume;
        double v_class = sqrt(2.0 * (U/effective_eps) / m);
        double gamma = 1.0 + (U/effective_eps) / (m * c * c);
        double beta2 = 1.0 - 1.0/(gamma*gamma);
        double v_rel = c * sqrt(beta2<=0.0?0.0:beta2);

        printf("INPUT  : D = %.3f km, rho = %.0f kg/m^3, epsilon = %.3f\n", D_km, rho, eps);
        printf("TARGET : U/epsilon_eff = %.6e J (eff. epsilon = %.3f)\n", U/effective_eps, effective_eps);
        printf("RESULT : Mass = %.6e kg (%.3f Mercury, %.3f Ceres)\n",
            m, m/MERCURY_MASS, m/CERES_MASS);
        printf("         Required speed (classical)    = %.3f km/s\n", v_class/1000.0);
        printf("         Required speed (relativistic) = %.3f km/s\n", v_rel/1000.0);
        if (v_rel >= 0.99*c) {
            printf("         NOTE: v_rel ~ c (ultra-relativistic).\n");
            printf("         CONCLUSION: %s SURVIVES - object too small to unbind planet\n", 
                planet_name ? planet_name : "TARGET");
        } else {
            printf("         CONCLUSION: %s DESTROYED at %.3f km/s impact\n", 
                planet_name ? planet_name : "TARGET", v_rel/1000.0);
        }
        return 0;
    }

    if (mode=='v' || mode=='V'){
        // Input: speed -> required mass & equivalent diameter (given density)
        double v_km_s = atof(argv[2]);
        double rho = (argc>3 && (!has_object || argc>4)) ? atof(argv[3]) : 3000.0;
        double eps = (argc>4 && has_object) ? atof(argv[4]) : (argc>3 && has_object ? 1.0 : 1.0);

        if (v_km_s <= 0.0 || rho <= 0.0 || eps <= 0.0){
            fprintf(stderr,"Inputs must be positive.\n"); return 1;
        }
        
        if (has_object) printf("OBJECT : %s\n", object_name);
        if (planet_name) {
            printf("PLANET : %s (U = %.6e J)\n", planet_name, U);
        } else {
            printf("PLANET : %s (U = %.6e J)\n", "target", U);                       
        }

        double v = v_km_s * 1000.0;
        double beta = v / c;
        if (beta >= 1.0){
            fprintf(stderr,"Speed must be < c.\n"); return 1;
        }
        
        // First calculate assuming no atmospheric losses to get initial diameter estimate
        double gamma = 1.0 / sqrt(1.0 - beta*beta);
        double k_per_mass = (gamma - 1.0) * c * c;
        double m_req = U / (eps * k_per_mass);
        double volume = m_req / rho;
        double D_initial = 2.0 * cbrt((3.0*volume)/(4.0*PI));
        double D_km_initial = D_initial / 1000.0;
        
        // Calculate atmospheric retention based on this diameter
        double retention = atmospheric_retention(D_km_initial, planet_type, material_type);
        double effective_eps = eps * retention;
        
        // Recalculate with atmospheric effects
        m_req = U / (effective_eps * k_per_mass);
        volume = m_req / rho;
        D_initial = 2.0 * cbrt((3.0*volume)/(4.0*PI));
        D_km_initial = D_initial / 1000.0;
        
        // Iterate once more for better accuracy
        retention = atmospheric_retention(D_km_initial, planet_type, material_type);
        effective_eps = eps * retention;
        m_req = U / (effective_eps * k_per_mass);
        volume = m_req / rho;
        double D = 2.0 * cbrt((3.0*volume)/(4.0*PI));
        double m_class = 2.0*U / (effective_eps * v * v);

        if (material_name) printf("MATERIAL: %s (retention = %.3f)\n", material_name, retention);
        printf("INPUT  : v = %.3f km/s, rho = %.0f kg/m^3, epsilon = %.3f\n", v_km_s, rho, eps);
        printf("TARGET : U/epsilon_eff = %.6e J (eff. epsilon = %.3f)\n", U/effective_eps, effective_eps);
        printf("RESULT : Minimum required mass (relativistic)   = %.6e kg (%.3f Mercury, %.3f Ceres)\n",
            m_req, m_req/MERCURY_MASS, m_req/CERES_MASS);
        printf("         Classical mass (for reference)         = %.6e kg\n", m_class);
        printf("         Minimum equivalent diameter            = %.3f km\n", D/1000.0);

        if (planet_name) {
            printf("         NOTE: Any impactor ≥ %.3f km at %.3f km/s will unbind %s\n", D/1000.0, v_km_s, planet_name);
        } else {
            printf("         NOTE: Any impactor ≥ %.3f km at %.3f km/s will unbind target\n", D/1000.0, v_km_s);                   
        }        
        return 0;
    }

    fprintf(stderr,"First arg must be 'm', 'd', or 'v'.\n");
    return 1;
}