#!/usr/bin/env python3
"""
unbindEnergy.py
Compute impactor size from speed, or speed from size/mass, to meet
the selected planet's unbinding energy U, with full relativistic kinetic energy.

Usage:
  Given speed -> required size (assume bulk density):
    python3 unbindEnergy.py v <speed_km_s> [rho_kg_m3=3000] [epsilon=1.0] [name] [planet] [material]
  Given diameter -> required speed (assume bulk density):
    python3 unbindEnergy.py d <diameter_km> [rho_kg_m3=3000] [epsilon=1.0] [name] [planet] [material]
  Given mass -> required speed:
    python3 unbindEnergy.py m <mass_kg> [epsilon=1.0] [name] [planet] [material]

Examples:
    python3 unbindEnergy.py m 1.2e17 0.25 "1036 Ganymed" earth stony
    python3 unbindEnergy.py d 0.375 2000 0.25 "Apophis at 2000 kg/m^3" jupiter stony
    python3 unbindEnergy.py m 1e9 0.25 Oumuamua mars cometary
    python3 unbindEnergy.py v 30000 2000 0.25 "30,000 km/s at 2000 kg/m^3" pluto stony
    python3 unbindEnergy.py d 0.375 2000 0.25 "Apophis at 2000 kg/m³" earth stony
    python3 unbindEnergy.py d 0.375 2000 0.25 "Apophis at 2000 kg/m³" mars iron  
    python3 unbindEnergy.py d 1.0 7800 0.25 "Iron asteroid" venus iron
    python3 unbindEnergy.py d 0.1 3000 1.0 "Small asteroid" jupiter stony
    python3 unbindEnergy.py d 5.0 3000 0.25 "Large comet" uranus cometary
    python3 unbindEnergy.py d 10.0 7800 1.0 "Massive iron" neptune iron
    python3 unbindEnergy.py d 0.01 1000 1.0 "Tiny rock" pluto stony

Where:
 - mass_kg = mass of impactor (kg) (1e9 to 1e23 typical range)
 - diameter_km = diameter of impactor (km) (0.1 to 1000 km typical range)
 - speed_km_s = velocity of impactor (km/s) (must be < c = 299,792.458 km/s)
 - rho_kg_m3 = bulk density of impactor (kg/m^3) (3000 is typical asteroid density)
 - epsilon = coupling efficiency (dimensionless) (fraction of KE that unbinds planet)
 - name = optional object identifier (e.g., "1036 Ganymed", "Apophis")
 - planet = target planet (earth, mars, venus, jupiter, saturn, uranus, neptune, pluto, moon, vacuum)
 - material = impactor material type (stony, iron, cometary)
 - U = Planet's gravitational binding energy (varies by planet)
 - c = speed of light (299,792,458 m/s)

Notes:
 - U varies by planet: Earth=2.49e32 J, Jupiter=2.06e36 J, Pluto=2.85e27 J, etc.
 - epsilon is coupling efficiency (fraction of KE that actually unbinds planet).
 - Atmospheric retention reduces effective coupling efficiency based on diameter, planet, and material
 - Outputs both classical and relativistic speeds for reference,
   but the relativistic result is the one to use at high energy.
 - Compares mass to Mercury and Ceres for scale context.
 - This model incorporates atmospheric effects and relativistic mechanics, but uses simplified assumptions for material fragmentation, energy coupling efficiency, and complex impact dynamics.
 - Classical KE = 0.5*m*v^2
 - Relativistic KE = (gamma-1)*m*c^2, where gamma = 1/sqrt(1-(v/c)^2)
 - For given KE, m = U/epsilon / KE_per_mass
 - For given m, v_classical = sqrt(2*U/epsilon/m)
 - For given m, gamma = 1 + U/epsilon/m/c^2
   then v_rel = c*sqrt(1-1/gamma^2)
 - For given diameter D and density rho, m = rho * (4/3)*pi*(D/2)^3
 - 1 km/s = 1000 m/s
 - 1 km = 1000 m
 - 1 AU = 1.496e11 m
 - Mercury mass = 3.30e23 kg
 - Ceres mass = 9.38e20 kg
"""

import sys
import math

# Planet type constants for atmospheric modeling
PLANET_EARTH = 0
PLANET_MARS = 1
PLANET_VENUS = 2
PLANET_JUPITER = 3
PLANET_SATURN = 4
PLANET_URANUS = 5
PLANET_NEPTUNE = 6
PLANET_PLUTO = 7
PLANET_MOON = 8
PLANET_VACUUM = 9

# Material type constants
MATERIAL_STONY = 0
MATERIAL_IRON = 1
MATERIAL_COMETARY = 2

def get_planetary_binding_energy(planet_type):
    """Function to get gravitational binding energy based on planet type"""
    binding_energies = {
        PLANET_EARTH: 2.49e32,    # J - Original value from code comments
        PLANET_MARS: 4.87e30,     # J - Calculated from NASA data
        PLANET_VENUS: 1.57e32,    # J - Calculated from NASA data
        PLANET_JUPITER: 2.06e36,  # J - Calculated from NASA data
        PLANET_SATURN: 2.22e35,   # J - Calculated from NASA data
        PLANET_URANUS: 1.19e34,   # J - Calculated from NASA data
        PLANET_NEPTUNE: 1.69e34,  # J - Calculated from NASA data
        PLANET_PLUTO: 2.85e27,    # J - Calculated from NASA data
        PLANET_MOON: 1.23e29,     # J - Moon binding energy
        PLANET_VACUUM: 2.49e32,   # J - Default to Earth
    }
    return binding_energies.get(planet_type, 2.49e32)  # Default to Earth

def atmospheric_retention(diameter_km, planet_type, material_type):
    """Returns fraction of kinetic energy that reaches surface"""
    
    if planet_type == PLANET_EARTH:
        if material_type == MATERIAL_IRON:  # Iron - higher survival rate
            if diameter_km < 0.01: return 0.00      # <10m: 0% retention
            if diameter_km < 0.03: return 0.20      # 10-30m: 20% retention
            if diameter_km < 0.05: return 0.50      # 30-50m: 50% retention  
            if diameter_km < 0.10: return 0.80      # 50-100m: 80% retention
            if diameter_km < 0.20: return 0.90      # 100-200m: 90% retention
            return 0.95                              # >200m: 95% retention
        elif material_type == MATERIAL_COMETARY:  # Cometary - very low survival
            if diameter_km < 0.05: return 0.00      # <50m: 0% retention
            if diameter_km < 0.20: return 0.05      # 50-200m: 5% retention
            return 0.80                              # >200m: 80% retention
        else:  # Stony (default)
            if diameter_km < 0.01: return 0.01      # <10m: 1% retention
            if diameter_km < 0.03: return 0.10      # 10-30m: 10% retention
            if diameter_km < 0.20: return 0.50      # 30-200m: 50% retention
            return 0.90                              # >200m: 90% retention
            
    elif planet_type == PLANET_MARS:
        # Mars: minimal atmospheric protection (1.3% of Earth's density)
        if material_type == MATERIAL_IRON:  # Iron
            if diameter_km < 0.001: return 0.80     # <1m: 80% retention
            return 0.95                              # >1m: 95% retention
        elif material_type == MATERIAL_COMETARY:  # Cometary
            if diameter_km < 0.01: return 0.70      # <10m: 70% retention
            return 0.90                              # >10m: 90% retention
        else:  # Stony
            if diameter_km < 0.005: return 0.85     # <5m: 85% retention
            return 0.95                              # >5m: 95% retention
            
    elif planet_type == PLANET_VENUS:
        # Venus: extreme atmospheric protection (53x denser than Earth)
        if material_type == MATERIAL_IRON:  # Iron - best survival chance
            if diameter_km < 0.10: return 0.00      # <100m: 0% retention
            if diameter_km < 0.50: return 0.10      # 100-500m: 10% retention
            if diameter_km < 1.00: return 0.50      # 500m-1km: 50% retention
            return 0.80                              # >1km: 80% retention
        elif material_type == MATERIAL_COMETARY:  # Cometary
            if diameter_km < 1.00: return 0.00      # <1km: 0% retention
            return 0.30                              # >1km: 30% retention
        else:  # Stony
            if diameter_km < 0.20: return 0.00      # <200m: 0% retention
            if diameter_km < 1.00: return 0.05      # 200m-1km: 5% retention
            return 0.60                              # >1km: 60% retention
            
    elif planet_type == PLANET_JUPITER:
        # Jupiter: massive atmospheric protection, crushing pressures
        if material_type == MATERIAL_IRON:  # Iron
            if diameter_km < 1.00: return 0.00      # <1km: 0% retention
            if diameter_km < 10.0: return 0.01      # 1-10km: 1% retention
            return 0.20                              # >10km: 20% retention
        else:  # Stony/Cometary - essentially no survival
            if diameter_km < 10.0: return 0.00      # <10km: 0% retention
            return 0.10                              # >10km: 10% retention
            
    elif planet_type == PLANET_SATURN:
        # Saturn: similar to Jupiter but larger scale height allows deeper penetration
        if material_type == MATERIAL_IRON:  # Iron
            if diameter_km < 0.50: return 0.00      # <500m: 0% retention
            if diameter_km < 5.00: return 0.05      # 500m-5km: 5% retention
            return 0.30                              # >5km: 30% retention
        else:  # Stony/Cometary
            if diameter_km < 5.00: return 0.00      # <5km: 0% retention
            return 0.15                              # >5km: 15% retention
            
    elif planet_type == PLANET_URANUS:
        # Uranus: ice giant with thick hydrogen/helium atmosphere + ices
        if material_type == MATERIAL_IRON:  # Iron
            if diameter_km < 2.00: return 0.00      # <2km: 0% retention
            if diameter_km < 10.0: return 0.02      # 2-10km: 2% retention
            return 0.25                              # >10km: 25% retention
        else:  # Stony/Cometary
            if diameter_km < 10.0: return 0.00      # <10km: 0% retention
            return 0.15                              # >10km: 15% retention
            
    elif planet_type == PLANET_NEPTUNE:
        # Neptune: densest ice giant, even more protective than Uranus
        if material_type == MATERIAL_IRON:  # Iron
            if diameter_km < 3.00: return 0.00      # <3km: 0% retention
            if diameter_km < 15.0: return 0.01      # 3-15km: 1% retention
            return 0.20                              # >15km: 20% retention
        else:  # Stony/Cometary
            if diameter_km < 15.0: return 0.00      # <15km: 0% retention
            return 0.10                              # >15km: 10% retention
            
    elif planet_type == PLANET_PLUTO:
        # Pluto: extremely thin nitrogen atmosphere (1 Pa vs Earth's 101,325 Pa)
        if material_type == MATERIAL_IRON:  # Iron
            if diameter_km < 0.001: return 0.95     # <1m: 95% retention
            return 0.99                              # >1m: 99% retention
        elif material_type == MATERIAL_COMETARY:  # Cometary
            if diameter_km < 0.01: return 0.90      # <10m: 90% retention
            return 0.98                              # >10m: 98% retention
        else:  # Stony
            if diameter_km < 0.005: return 0.92     # <5m: 92% retention
            return 0.98                              # >5m: 98% retention

    elif planet_type == PLANET_MOON:
        # Moon: essentially no atmosphere (3×10^-15 Pa vs Earth's 101,325 Pa)
        # Extremely thin exosphere provides virtually no protection
        if material_type == MATERIAL_IRON:  # Iron
            if diameter_km < 0.001: return 0.99     # <1m: 99% retention
            return 1.00                              # >1m: 100% retention
        elif material_type == MATERIAL_COMETARY:  # Cometary
            if diameter_km < 0.001: return 0.98     # <1m: 98% retention
            return 0.99                              # >1m: 99% retention
        else:  # Stony
            if diameter_km < 0.001: return 0.99     # <1m: 99% retention
            return 1.00                              # >1m: 100% retention
            
    else:  # PLANET_VACUUM or default
        return 1.00  # No atmospheric losses

def get_planet_type(planet_name):
    """Helper function to get planet type from string"""
    if not planet_name:
        return PLANET_EARTH  # default
    
    planet_name = planet_name.lower()
    planet_map = {
        'earth': PLANET_EARTH,
        'mars': PLANET_MARS,
        'venus': PLANET_VENUS,
        'jupiter': PLANET_JUPITER,
        'saturn': PLANET_SATURN,
        'uranus': PLANET_URANUS,
        'neptune': PLANET_NEPTUNE,
        'pluto': PLANET_PLUTO,
        'moon': PLANET_MOON,
        'vacuum': PLANET_VACUUM
    }
    return planet_map.get(planet_name, PLANET_EARTH)  # default to Earth if unknown

def get_material_type(material_name):
    """Helper function to get material type from string"""
    if not material_name:
        return MATERIAL_STONY  # default to stony
    
    material_name = material_name.lower()
    material_map = {
        'iron': MATERIAL_IRON,
        'cometary': MATERIAL_COMETARY,
        'stony': MATERIAL_STONY
    }
    return material_map.get(material_name, MATERIAL_STONY)  # default to stony

def is_number(s):
    """Check if string can be converted to float"""
    try:
        float(s)
        return True
    except ValueError:
        return False

def main():
    c = 299792458.0             # m/s
    PI = math.pi                # PI
    MERCURY_MASS = 3.30e23      # kg
    CERES_MASS = 9.38e20        # kg

    object_name = None
    planet_name = None
    material_name = None
    has_object = False
    has_atmospheric = False
    planet_type = PLANET_EARTH  # default to Earth
    material_type = MATERIAL_STONY  # default to stony

    argc = len(sys.argv)
    
    if argc > 3:
        # Check for atmospheric parameters (planet and material) at the end
        if argc >= 6:
            # Check if last two arguments are not numbers (planet and material)
            if not is_number(sys.argv[-2]) and not is_number(sys.argv[-1]):
                planet_name = sys.argv[-2]
                material_name = sys.argv[-1]
                has_atmospheric = True
                
                # Check for object name before planet/material
                if argc >= 7:
                    if not is_number(sys.argv[-3]):
                        object_name = sys.argv[-3]
                        has_object = True
        
        # If no atmospheric params, check for object name as last argument
        if not has_atmospheric:
            last_arg = sys.argv[-1]
            if not is_number(last_arg):  # not a valid number, treat as name
                object_name = last_arg
                has_object = True

    # Determine planet type and set binding energy
    planet_type = get_planet_type(planet_name)
    material_type = get_material_type(material_name)
    U = get_planetary_binding_energy(planet_type)

    if argc < 3:
        print(f"Usage:")
        print(f"  python3 {sys.argv[0]} m <mass_kg> [epsilon=1.0] [name] [planet/body] [impactor material]")
        print(f"  python3 {sys.argv[0]} d <diameter_km> [rho_kg_m3=3000] [epsilon=1.0] [name] [planet/body] [impactor material]")
        print(f"  python3 {sys.argv[0]} v <speed_km_s> [rho_kg_m3=3000] [epsilon=1.0] [name] [planet/body] [impactor material]")
        return 1

    mode = sys.argv[1][0].lower()

    if mode == 'm':
        # Input: mass -> required speed (both classical & relativistic)
        m = float(sys.argv[2])
        eps = float(sys.argv[3]) if (argc > 3 and (not has_object or argc > 4)) else 1.0
        
        if m <= 0.0 or eps <= 0.0:
            print("Inputs must be positive.")
            return 1
        
        # Estimate diameter from mass to calculate atmospheric retention
        volume = m / 3000.0  # Assume 3000 kg/m³ density for estimation
        D_km = 2.0 * ((3.0 * volume) / (4.0 * PI))**(1.0/3.0) / 1000.0
        retention = atmospheric_retention(D_km, planet_type, material_type)
        effective_eps = eps * retention
        
        if has_object:
            print(f"OBJECT : {object_name}")
        if planet_name:
            print(f"PLANET : {planet_name} (U = {U:.6e} J)")
        if material_name:
            print(f"MATERIAL: {material_name} (retention = {retention:.3f})")

        print(f"INPUT  : m = {m:.6e} kg, epsilon = {eps:.3f}")
        print(f"TARGET : U/epsilon_eff = {U/effective_eps:.6e} J (eff. epsilon = {effective_eps:.3f})")
        
        v_class = math.sqrt(2.0 * (U/effective_eps) / m)
        gamma = 1.0 + (U/effective_eps) / (m * c * c)
        beta2 = 1.0 - 1.0 / (gamma * gamma)
        v_rel = c * math.sqrt(max(0.0, beta2))
        
        print(f"RESULT : Required speed (classical)    = {v_class/1000.0:.3f} km/s")
        print(f"         Required speed (relativistic) = {v_rel/1000.0:.3f} km/s")
        
        if v_rel >= 0.99 * c:
            print("         NOTE: v_rel ~ c (ultra-relativistic).")
            print(f"         CONCLUSION: {planet_name or 'TARGET'} SURVIVES - object too small to unbind planet")
        else:
            print(f"         CONCLUSION: {planet_name or 'TARGET'} DESTROYED at {v_rel/1000.0:.3f} km/s impact")
        
        return 0

    elif mode == 'd':
        # Input: diameter -> required speed (both classical & relativistic)
        D_km = float(sys.argv[2])
        rho = float(sys.argv[3]) if (argc > 3 and (not has_object or argc > 4)) else 3000.0
        eps = float(sys.argv[4]) if (argc > 4 and has_object) else (1.0 if argc > 3 and has_object else 1.0)
        
        if D_km <= 0.0 or rho <= 0.0 or eps <= 0.0:
            print("Inputs must be positive.")
            return 1
        
        # Calculate atmospheric retention based on diameter
        retention = atmospheric_retention(D_km, planet_type, material_type)
        effective_eps = eps * retention
        
        if has_object:
            print(f"OBJECT : {object_name}")
        if planet_name:
            print(f"PLANET : {planet_name} (U = {U:.6e} J)")
        if material_name:
            print(f"MATERIAL: {material_name} (retention = {retention:.3f})")

        D = D_km * 1000.0
        volume = (4.0/3.0) * PI * (D/2.0)**3
        m = rho * volume
        v_class = math.sqrt(2.0 * (U/effective_eps) / m)
        gamma = 1.0 + (U/effective_eps) / (m * c * c)
        beta2 = 1.0 - 1.0 / (gamma * gamma)
        v_rel = c * math.sqrt(max(0.0, beta2))

        print(f"INPUT  : D = {D_km:.3f} km, rho = {rho:.0f} kg/m^3, epsilon = {eps:.3f}")
        print(f"TARGET : U/epsilon_eff = {U/effective_eps:.6e} J (eff. epsilon = {effective_eps:.3f})")
        print(f"RESULT : Mass = {m:.6e} kg ({m/MERCURY_MASS:.3f} Mercury, {m/CERES_MASS:.3f} Ceres)")
        print(f"         Required speed (classical)    = {v_class/1000.0:.3f} km/s")
        print(f"         Required speed (relativistic) = {v_rel/1000.0:.3f} km/s")
        
        if v_rel >= 0.99 * c:
            print("         NOTE: v_rel ~ c (ultra-relativistic).")
            print(f"         CONCLUSION: {planet_name or 'TARGET'} SURVIVES - object too small to unbind planet")
        else:
            print(f"         CONCLUSION: {planet_name or 'TARGET'} DESTROYED at {v_rel/1000.0:.3f} km/s impact")
        
        return 0

    elif mode == 'v':
        # Input: speed -> required mass & equivalent diameter (given density)
        v_km_s = float(sys.argv[2])
        rho = float(sys.argv[3]) if (argc > 3 and (not has_object or argc > 4)) else 3000.0
        eps = float(sys.argv[4]) if (argc > 4 and has_object) else (1.0 if argc > 3 and has_object else 1.0)

        if v_km_s <= 0.0 or rho <= 0.0 or eps <= 0.0:
            print("Inputs must be positive.")
            return 1
            
        if has_object:
            print(f"OBJECT : {object_name}")
        if planet_name:
            print(f"PLANET : {planet_name} (U = {U:.6e} J)")
        else:
            print(f"PLANET : target (U = {U:.6e} J)")

        v = v_km_s * 1000.0
        beta = v / c
        if beta >= 1.0:
            print("Speed must be < c.")
            return 1
        
        # First calculate assuming no atmospheric losses to get initial diameter estimate
        gamma = 1.0 / math.sqrt(1.0 - beta * beta)
        k_per_mass = (gamma - 1.0) * c * c
        m_req = U / (eps * k_per_mass)
        volume = m_req / rho
        D_initial = 2.0 * ((3.0 * volume) / (4.0 * PI))**(1.0/3.0)
        D_km_initial = D_initial / 1000.0
        
        # Calculate atmospheric retention based on this diameter
        retention = atmospheric_retention(D_km_initial, planet_type, material_type)
        effective_eps = eps * retention
        
        # Recalculate with atmospheric effects
        m_req = U / (effective_eps * k_per_mass)
        volume = m_req / rho
        D_initial = 2.0 * ((3.0 * volume) / (4.0 * PI))**(1.0/3.0)
        D_km_initial = D_initial / 1000.0
        
        # Iterate once more for better accuracy
        retention = atmospheric_retention(D_km_initial, planet_type, material_type)
        effective_eps = eps * retention
        m_req = U / (effective_eps * k_per_mass)
        volume = m_req / rho
        D = 2.0 * ((3.0 * volume) / (4.0 * PI))**(1.0/3.0)
        m_class = 2.0 * U / (effective_eps * v * v)

        if material_name:
            print(f"MATERIAL: {material_name} (retention = {retention:.3f})")
        print(f"INPUT  : v = {v_km_s:.3f} km/s, rho = {rho:.0f} kg/m^3, epsilon = {eps:.3f}")
        print(f"TARGET : U/epsilon_eff = {U/effective_eps:.6e} J (eff. epsilon = {effective_eps:.3f})")
        print(f"RESULT : Minimum required mass (relativistic)   = {m_req:.6e} kg ({m_req/MERCURY_MASS:.3f} Mercury, {m_req/CERES_MASS:.3f} Ceres)")
        print(f"         Classical mass (for reference)         = {m_class:.6e} kg")
        print(f"         Minimum equivalent diameter            = {D/1000.0:.3f} km")

        if planet_name:
            print(f"         NOTE: Any impactor ≥ {D/1000.0:.3f} km at {v_km_s:.3f} km/s will unbind {planet_name}")
        else:
            print(f"         NOTE: Any impactor ≥ {D/1000.0:.3f} km at {v_km_s:.3f} km/s will unbind target")
        
        return 0

    else:
        print("First arg must be 'm', 'd', or 'v'.")
        return 1

if __name__ == "__main__":
    sys.exit(main())