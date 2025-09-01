$CONSOLE:ONLY
'----------------------------------------------------------------
' unbindEnergy.bas
' (C) 2025 - George McGinn - MIT License
' Compute impactor size from speed, or speed from size/mass, to meet
' the selected planet's unbinding energy U, with full relativistic kinetic energy.
' Build: Run in QB64 or QB64PE environment
' Compile: qb64pe -x unbindEnergy.bas -o unbindEnergy
' Compile: qb64pe -x /path/to/unbindEnergy.bas -o /path/to/unbindEnergy
'
' Usage:
'   Given speed -> required size (assume bulk density):
'     unbindEnergy v <speed_km_s> [rho_kg_m3=3000] [epsilon=1.0] [name] [planet] [material]
'   Given diameter -> required speed (assume bulk density):
'     unbindEnergy d <diameter_km> [rho_kg_m3=3000] [epsilon=1.0] [name] [planet] [material]
'   Given mass -> required speed:
'     unbindEnergy m <mass_kg> [epsilon=1.0] [name] [planet] [material]
'
' Examples:
'     unbindEnergy m 1.2e17 0.25 "1036 Ganymed" earth stony
'     unbindEnergy d 0.375 2000 0.25 "Apophis at 2000 kg/m^3" jupiter stony
'     unbindEnergy m 1e9 0.25 Oumuamua mars cometary
'     unbindEnergy v 30000 2000 0.25 "30,000 km/s at 2000 kg/m^3" pluto stony
'     unbindEnergy d 0.375 2000 0.25 "Apophis at 2000 kg/m³" earth stony
'     unbindEnergy d 0.375 2000 0.25 "Apophis at 2000 kg/m³" mars iron
'     unbindEnergy d 1.0 7800 0.25 "Iron asteroid" venus iron
'     unbindEnergy d 0.1 3000 1.0 "Small asteroid" jupiter stony
'     unbindEnergy d 5.0 3000 0.25 "Large comet" uranus cometary
'     unbindEnergy d 10.0 7800 1.0 "Massive iron" neptune iron
'     unbindEnergy d 0.01 1000 1.0 "Tiny rock" pluto stony
'
' Where:
'  - mass_kg = mass of impactor (kg) (1e9 to 1e23 typical range)
'  - diameter_km = diameter of impactor (km) (0.1 to 1000 km typical range)
'  - speed_km_s = velocity of impactor (km/s) (must be < c = 299,792.458 km/s)
'  - rho_kg_m3 = bulk density of impactor (kg/m^3) (3000 is typical asteroid density)
'  - epsilon = coupling efficiency (dimensionless) (fraction of KE that unbinds planet)
'  - name = optional object identifier (e.g., "1036 Ganymed", "Apophis")
'  - planet = target planet (earth, mars, venus, jupiter, saturn, uranus, neptune, pluto, moon, vacuum)
'  - material = impactor material type (stony, iron, cometary)
'  - U = Planet's gravitational binding energy (varies by planet)
'  - c = speed of light (299,792,458 m/s)
'
' Notes:
'  - U varies by planet: Earth=2.49e32 J, Jupiter=2.06e36 J, Pluto=2.85e27 J, etc.
'  - epsilon is coupling efficiency (fraction of KE that actually unbinds planet).
'  - Atmospheric retention reduces effective coupling efficiency based on diameter, planet, and material
'  - Outputs both classical and relativistic speeds for reference,
'    but the relativistic result is the one to use at high energy.
'  - Compares mass to Mercury and Ceres for scale context.
'  - This model incorporates atmospheric effects and relativistic mechanics, but uses simplified assumptions for material fragmentation, energy coupling efficiency, and complex impact dynamics.
'  - Classical KE = 0.5*m*v^2
'  - Relativistic KE = (gamma-1)*m*c^2, where gamma = 1/sqrt(1-(v/c)^2)
'  - For given KE, m = U/epsilon / KE_per_mass
'  - For given m, v_classical = sqrt(2*U/epsilon/m)
'  - For given m, gamma = 1 + U/epsilon/m/c^2
'    then v_rel = c*sqrt(1-1/gamma^2)
'  - For given diameter D and density rho, m = rho * (4/3)*pi*(D/2)^3
'  - 1 km/s = 1000 m/s
'  - 1 km = 1000 m
'  - 1 AU = 1.496e11 m
'  - Mercury mass = 3.30e23 kg
'  - Ceres mass = 9.38e20 kg
'----------------------------------------------------------------

' Constants
DIM SHARED LIGHT_SPEED  AS DOUBLE
DIM SHARED PI_VAL       AS DOUBLE
DIM SHARED MERCURY_MASS AS DOUBLE
DIM SHARED CERES_MASS   AS DOUBLE
LIGHT_SPEED = 299792458          ' m/s
PI_VAL = 3.14159265358979323846  ' PI
MERCURY_MASS = 3.30E+23          ' kg
CERES_MASS = 9.38E+20            ' kg

' Planet type constants for atmospheric modeling
DIM SHARED PLANET_EARTH   AS INTEGER: PLANET_EARTH = 0
DIM SHARED PLANET_MARS    AS INTEGER: PLANET_MARS = 1
DIM SHARED PLANET_VENUS   AS INTEGER: PLANET_VENUS = 2
DIM SHARED PLANET_JUPITER AS INTEGER: PLANET_JUPITER = 3
DIM SHARED PLANET_SATURN  AS INTEGER: PLANET_SATURN = 4
DIM SHARED PLANET_URANUS  AS INTEGER: PLANET_URANUS = 5
DIM SHARED PLANET_NEPTUNE AS INTEGER: PLANET_NEPTUNE = 6
DIM SHARED PLANET_PLUTO   AS INTEGER: PLANET_PLUTO = 7
DIM SHARED PLANET_MOON    AS INTEGER: PLANET_MOON = 8
DIM SHARED PLANET_VACUUM  AS INTEGER: PLANET_VACUUM = 9

' Material type constants
DIM SHARED MATERIAL_STONY    AS INTEGER: MATERIAL_STONY = 0
DIM SHARED MATERIAL_IRON     AS INTEGER: MATERIAL_IRON = 1
DIM SHARED MATERIAL_COMETARY AS INTEGER: MATERIAL_COMETARY = 2

TRUE = -1
FALSE = 0

' Parse command line arguments
DIM cmd           AS STRING
DIM args(1 TO 25) AS STRING
DIM arg_count     AS INTEGER
DIM object_name   AS STRING
DIM planet_name   AS STRING
DIM material_name AS STRING
DIM has_object    AS INTEGER
DIM has_atmospheric AS INTEGER
DIM planet_type   AS INTEGER
DIM material_type AS INTEGER
DIM U_binding     AS DOUBLE

cmd = COMMAND$
arg_count = 0
has_object = 0
has_atmospheric = 0
object_name = ""
planet_name = ""
material_name = ""
planet_type = PLANET_EARTH ' default to Earth
material_type = MATERIAL_STONY ' default to stony

' Setup NUMERIC Check Table
DIM SHARED numeric(255) AS INTEGER
FOR I = 48 TO 57
    numeric(I) = -1
NEXT
numeric(ASC(".")) = -1 ' Allow decimal point
numeric(ASC("-")) = -1 ' Allow negative sign  
numeric(ASC("+")) = -1 ' Allow positive sign
numeric(ASC("e")) = -1 ' Allow scientific notation
numeric(ASC("E")) = -1 ' Allow scientific notation

' Parse command line into arguments
IF LEN(cmd) > 0 THEN
    arg_count = ParseArgs(cmd, args())
END IF

' Check for atmospheric parameters (planet and material) at the end
IF arg_count >= 6 THEN
    ' Check if last two arguments are not numbers (planet and material)
    IF NOT IsNumeric(args(arg_count - 1)) AND NOT IsNumeric(args(arg_count)) THEN
        planet_name = args(arg_count - 1)
        material_name = args(arg_count)
        has_atmospheric = 1
        arg_count = arg_count - 2
        
        ' Check for object name before planet/material
        IF arg_count >= 4 THEN
            IF NOT IsNumeric(args(arg_count)) THEN
                object_name = args(arg_count)
                has_object = 1
                arg_count = arg_count - 1
            END IF
        END IF
    END IF
END IF

' If no atmospheric params, check for object name as last argument
IF has_atmospheric = 0 THEN
    IF arg_count > 3 THEN
        IF NOT IsNumeric(args(arg_count)) THEN
            object_name = args(arg_count)
            has_object = 1
            arg_count = arg_count - 1
        END IF
    END IF
END IF

' Determine planet type and set binding energy
planet_type = GetPlanetType(planet_name)
material_type = GetMaterialType(material_name)
U_binding = GetPlanetaryBindingEnergy(planet_type)

IF arg_count < 2 THEN
    PRINT "Usage:"
    PRINT "  unbindEnergy m <mass_kg> [epsilon=1.0] [name] [planet/body] [impactor material]"
    PRINT "  unbindEnergy d <diameter_km> [rho_kg_m3=3000] [epsilon=1.0] [name] [planet/body] [impactor material]"
    PRINT "  unbindEnergy v <speed_km_s> [rho_kg_m3=3000] [epsilon=1.0] [name] [planet/body] [impactor material]"
    END
END IF

DIM mode_char AS STRING
mode_char = UCASE$(LEFT$(args(1), 1))

IF mode_char = "M" THEN
    ' Input: mass -> required speed (both classical & relativistic)
    DIM mass_val AS DOUBLE
    DIM epsilon  AS DOUBLE
    
    mass_val = VAL(args(2))
    epsilon = 1.0
    IF arg_count > 2 THEN epsilon = VAL(args(3))
    
    IF mass_val <= 0 OR epsilon <= 0 THEN
        PRINT "Inputs must be positive."
        END
    END IF
    
    ' Estimate diameter from mass to calculate atmospheric retention
    DIM volume AS DOUBLE, D_km AS DOUBLE, retention AS DOUBLE, effective_eps AS DOUBLE
    volume = mass_val / 3000.0 ' Assume 3000 kg/m³ density for estimation
    D_km = 2.0 * ((3.0 * volume) / (4.0 * PI_VAL)) ^ (1.0 / 3.0) / 1000.0
    retention = AtmosphericRetention(D_km, planet_type, material_type)
    effective_eps = epsilon * retention
    
    IF has_object THEN PRINT "OBJECT : "; object_name
    IF LEN(planet_name) > 0 THEN PRINT "PLANET : "; planet_name; " (U = "; : PRINT USING "##.######^^^^"; U_binding; : PRINT " J)"
    IF LEN(material_name) > 0 THEN PRINT "MATERIAL: "; material_name; " (retention = "; : PRINT USING "##.###"; retention; : PRINT ")"
    
    PRINT "INPUT  : m = "; : PRINT USING "##.######^^^^"; mass_val; : PRINT " kg, epsilon = "; : PRINT USING "##.###"; epsilon
    PRINT "TARGET : U/epsilon_eff = "; : PRINT USING "##.######^^^^"; U_binding / effective_eps; : PRINT " J (eff. epsilon = "; : PRINT USING "##.###"; effective_eps; : PRINT ")"
    
    DIM v_classical    AS DOUBLE
    DIM gamma_factor   AS DOUBLE
    DIM v_relativistic AS DOUBLE
    DIM beta_squared   AS DOUBLE
    
    v_classical = SQR(2.0 * (U_binding / effective_eps) / mass_val)
    gamma_factor = 1.0 + (U_binding / effective_eps) / (mass_val * LIGHT_SPEED * LIGHT_SPEED)
    beta_squared = 1.0 - 1.0 / (gamma_factor * gamma_factor)
    IF beta_squared <= 0 THEN beta_squared = 0
    v_relativistic = LIGHT_SPEED * SQR(beta_squared)
    
    PRINT "RESULT : Required speed (classical)    = "; : PRINT USING "#########.###"; v_classical / 1000.0; : PRINT " km/s"
    PRINT "         Required speed (relativistic) = "; : PRINT USING "#########.###"; v_relativistic / 1000.0; : PRINT " km/s"
    
    IF v_relativistic >= 0.99 * LIGHT_SPEED THEN
        PRINT "         NOTE: v_rel ~ c (ultra-relativistic)."
        DIM planet_display AS STRING
        IF LEN(planet_name) > 0 THEN planet_display = planet_name ELSE planet_display = "TARGET"
        PRINT "         CONCLUSION: "; planet_display; " SURVIVES - object too small to unbind planet"
    ELSE
        DIM planet_display2 AS STRING
        IF LEN(planet_name) > 0 THEN planet_display2 = planet_name ELSE planet_display2 = "TARGET"
        PRINT "         CONCLUSION: "; planet_display2; " DESTROYED at "; : PRINT USING "#########.###"; v_relativistic / 1000.0; : PRINT " km/s impact"
    END IF
    
ELSEIF mode_char = "D" THEN
    ' Input: diameter -> required speed (both classical & relativistic)
    DIM diameter_km AS DOUBLE
    DIM density_val AS DOUBLE
    DIM eps_d       AS DOUBLE
    
    diameter_km = VAL(args(2))
    density_val = 3000.0
    eps_d = 1.0
    
    IF arg_count > 2 THEN density_val = VAL(args(3))
    IF arg_count > 3 THEN eps_d = VAL(args(4))
    
    IF diameter_km <= 0 OR density_val <= 0 OR eps_d <= 0 THEN
        PRINT "Inputs must be positive."
        END
    END IF
    
    ' Calculate atmospheric retention based on diameter
    DIM retention_d AS DOUBLE, effective_eps_d AS DOUBLE
    retention_d = AtmosphericRetention(diameter_km, planet_type, material_type)
    effective_eps_d = eps_d * retention_d
    
    IF has_object THEN PRINT "OBJECT : "; object_name
    IF LEN(planet_name) > 0 THEN PRINT "PLANET : "; planet_name; " (U = "; : PRINT USING "##.######^^^^"; U_binding; : PRINT " J)"
    IF LEN(material_name) > 0 THEN PRINT "MATERIAL: "; material_name; " (retention = "; : PRINT USING "##.###"; retention_d; : PRINT ")"
    
    DIM diameter_m    AS DOUBLE
    DIM sphere_volume AS DOUBLE
    DIM sphere_mass   AS DOUBLE
    DIM v_class_d     AS DOUBLE
    DIM gamma_d       AS DOUBLE
    DIM beta2_d       AS DOUBLE
    DIM v_rel_d       AS DOUBLE
    
    diameter_m = diameter_km * 1000.0
    sphere_volume = (4.0 / 3.0) * PI_VAL * (diameter_m / 2.0) ^ 3
    sphere_mass = density_val * sphere_volume
    v_class_d = SQR(2.0 * (U_binding / effective_eps_d) / sphere_mass)
    gamma_d = 1.0 + (U_binding / effective_eps_d) / (sphere_mass * LIGHT_SPEED * LIGHT_SPEED)
    beta2_d = 1.0 - 1.0 / (gamma_d * gamma_d)
    IF beta2_d <= 0 THEN beta2_d = 0
    v_rel_d = LIGHT_SPEED * SQR(beta2_d)
    
    PRINT "INPUT  : D = "; : PRINT USING "####.###"; diameter_km; : PRINT " km, rho = "; : PRINT USING "#####"; density_val; : PRINT " kg/m^3, epsilon = "; : PRINT USING "##.###"; eps_d
    PRINT "TARGET : U/epsilon_eff = "; : PRINT USING "##.######^^^^"; U_binding / effective_eps_d; : PRINT " J (eff. epsilon = "; : PRINT USING "##.###"; effective_eps_d; : PRINT ")"
    PRINT "RESULT : Mass = "; : PRINT USING "##.######^^^^"; sphere_mass; : PRINT " kg ("; : PRINT USING "##.###"; sphere_mass / MERCURY_MASS; : PRINT " Mercury, "; : PRINT USING "##.###"; sphere_mass / CERES_MASS; : PRINT " Ceres)"
    PRINT "         Required speed (classical)    = "; : PRINT USING "#########.###"; v_class_d / 1000.0; : PRINT " km/s"
    PRINT "         Required speed (relativistic) = "; : PRINT USING "#########.###"; v_rel_d / 1000.0; : PRINT " km/s"
    
    IF v_rel_d >= 0.99 * LIGHT_SPEED THEN
        PRINT "         NOTE: v_rel ~ c (ultra-relativistic)."
        DIM planet_display_d AS STRING
        IF LEN(planet_name) > 0 THEN planet_display_d = planet_name ELSE planet_display_d = "TARGET"
        PRINT "         CONCLUSION: "; planet_display_d; " SURVIVES - object too small to unbind planet"
    ELSE
        DIM planet_display_d2 AS STRING
        IF LEN(planet_name) > 0 THEN planet_display_d2 = planet_name ELSE planet_display_d2 = "TARGET"
        PRINT "         CONCLUSION: "; planet_display_d2; " DESTROYED at "; : PRINT USING "#########.###"; v_rel_d / 1000.0; : PRINT " km/s impact"
    END IF
    
ELSEIF mode_char = "V" THEN
    ' Input: speed -> required mass & equivalent diameter (given density)
    DIM velocity_km_s AS DOUBLE
    DIM rho_v         AS DOUBLE
    DIM eps_v         AS DOUBLE
    
    velocity_km_s = VAL(args(2))
    rho_v = 3000.0
    eps_v = 1.0
    
    IF arg_count > 2 THEN rho_v = VAL(args(3))
    IF arg_count > 3 THEN eps_v = VAL(args(4))
    
    IF velocity_km_s <= 0 OR rho_v <= 0 OR eps_v <= 0 THEN
        PRINT "Inputs must be positive."
        END
    END IF
    
    IF has_object THEN PRINT "OBJECT : "; object_name
    IF LEN(planet_name) > 0 THEN
        PRINT "PLANET : "; planet_name; " (U = "; : PRINT USING "##.######^^^^"; U_binding; : PRINT " J)"
    ELSE
        PRINT "PLANET : target (U = "; : PRINT USING "##.######^^^^"; U_binding; : PRINT " J)"
    END IF
    
    DIM velocity_m_s     AS DOUBLE
    DIM beta_val         AS DOUBLE
    DIM gamma_v          AS DOUBLE
    DIM kinetic_per_mass AS DOUBLE
    DIM mass_required    AS DOUBLE
    DIM req_volume       AS DOUBLE
    DIM D_initial        AS DOUBLE
    DIM D_km_initial     AS DOUBLE
    DIM retention_v      AS DOUBLE
    DIM effective_eps_v  AS DOUBLE
    DIM req_diameter     AS DOUBLE
    DIM classical_mass   AS DOUBLE
    
    velocity_m_s = velocity_km_s * 1000.0
    beta_val = velocity_m_s / LIGHT_SPEED
    
    IF beta_val >= 1.0 THEN
        PRINT "Speed must be < c."
        END
    END IF
    
    ' First calculate assuming no atmospheric losses to get initial diameter estimate
    gamma_v = 1.0 / SQR(1.0 - beta_val * beta_val)
    kinetic_per_mass = (gamma_v - 1.0) * LIGHT_SPEED * LIGHT_SPEED
    mass_required = U_binding / (eps_v * kinetic_per_mass)
    req_volume = mass_required / rho_v
    D_initial = 2.0 * ((3.0 * req_volume) / (4.0 * PI_VAL)) ^ (1.0 / 3.0)
    D_km_initial = D_initial / 1000.0
    
    ' Calculate atmospheric retention based on this diameter
    retention_v = AtmosphericRetention(D_km_initial, planet_type, material_type)
    effective_eps_v = eps_v * retention_v
    
    ' Recalculate with atmospheric effects
    mass_required = U_binding / (effective_eps_v * kinetic_per_mass)
    req_volume = mass_required / rho_v
    D_initial = 2.0 * ((3.0 * req_volume) / (4.0 * PI_VAL)) ^ (1.0 / 3.0)
    D_km_initial = D_initial / 1000.0
    
    ' Iterate once more for better accuracy
    retention_v = AtmosphericRetention(D_km_initial, planet_type, material_type)
    effective_eps_v = eps_v * retention_v
    mass_required = U_binding / (effective_eps_v * kinetic_per_mass)
    req_volume = mass_required / rho_v
    req_diameter = 2.0 * ((3.0 * req_volume) / (4.0 * PI_VAL)) ^ (1.0 / 3.0)
    classical_mass = 2.0 * U_binding / (effective_eps_v * velocity_m_s * velocity_m_s)
    
    IF LEN(material_name) > 0 THEN PRINT "MATERIAL: "; material_name; " (retention = "; : PRINT USING "##.###"; retention_v; : PRINT ")"
    PRINT "INPUT  : v = "; : PRINT USING "####.###"; velocity_km_s; : PRINT " km/s, rho = "; : PRINT USING "#####"; rho_v; : PRINT " kg/m^3, epsilon = "; : PRINT USING "##.###"; eps_v
    PRINT "TARGET : U/epsilon_eff = "; : PRINT USING "##.######^^^^"; U_binding / effective_eps_v; : PRINT " J (eff. epsilon = "; : PRINT USING "##.###"; effective_eps_v; : PRINT ")"
    PRINT "RESULT : Minimum required mass (relativistic)   = "; : PRINT USING "##.######^^^^"; mass_required; : PRINT " kg ("; : PRINT USING "##.###"; mass_required / MERCURY_MASS; : PRINT " Mercury, "; : PRINT USING "##.###"; mass_required / CERES_MASS; : PRINT " Ceres)"
    PRINT "         Classical mass (for reference)         = "; : PRINT USING "##.######^^^^"; classical_mass; : PRINT " kg"
    PRINT "         Minimum equivalent diameter            = "; : PRINT USING "####.###"; req_diameter / 1000.0; : PRINT " km"
    
    DIM planet_display_v AS STRING
    IF LEN(planet_name) > 0 THEN planet_display_v = planet_name ELSE planet_display_v = "target"
    PRINT "         NOTE: Any impactor >= "; : PRINT USING "####.###"; req_diameter / 1000.0; : PRINT " km at "; : PRINT USING "####.###"; velocity_km_s; : PRINT " km/s will unbind "; planet_display_v
    
ELSE
    PRINT "First arg must be 'm', 'd', or 'v'."
END IF

SYSTEM 0

' Functions and subroutines placed at the end per QB64 requirements
FUNCTION ParseArgs (cmdline AS STRING, args() AS STRING)
    DIM count       AS INTEGER
    DIM i           AS INTEGER
    DIM temp        AS STRING
    DIM in_quotes   AS INTEGER
    DIM current_arg AS STRING
    
    count = 0
    i = 1
    in_quotes = 0
    current_arg = ""
    temp = cmdline + " "
    
    WHILE i <= LEN(temp)
        DIM char AS STRING
        char = MID$(temp, i, 1)
        
        IF char = CHR$(34) THEN ' Quote character
            in_quotes = 1 - in_quotes
        ELSEIF char = " " AND in_quotes = 0 THEN
            IF LEN(current_arg) > 0 THEN
                count = count + 1
                args(count) = current_arg
                current_arg = ""
            END IF
        ELSE
            IF char <> CHR$(34) THEN current_arg = current_arg + char
        END IF
        i = i + 1
    WEND
    
    ' Add final argument if it exists
    IF LEN(current_arg) > 0 THEN
        count = count + 1
        args(count) = current_arg
    END IF
    
    ParseArgs = count
END FUNCTION

FUNCTION IsNumeric (A$)
'-----------------------------------------------------
' *** Numeric Check of a STRING including scientific notation
    DIM l AS INTEGER, I AS INTEGER, ACODE AS INTEGER
    l = LEN(A$)
    IF l = 0 THEN IsNumeric = 0: EXIT FUNCTION
    
    FOR I = 1 TO l
        ACODE = ASC(A$, I)
        IF NOT numeric(ACODE) THEN
            IsNumeric = 0
            EXIT FUNCTION
        END IF
    NEXT I
    IsNumeric = -1
END FUNCTION

FUNCTION GetPlanetaryBindingEnergy (planet_type AS INTEGER)
    ' Function to get gravitational binding energy based on planet type
    SELECT CASE planet_type
        CASE 0 ' PLANET_EARTH
            GetPlanetaryBindingEnergy = 2.49E+32 ' J - Original value from code comments
        CASE 1 ' PLANET_MARS
            GetPlanetaryBindingEnergy = 4.87E+30 ' J - Calculated from NASA data
        CASE 2 ' PLANET_VENUS
            GetPlanetaryBindingEnergy = 1.57E+32 ' J - Calculated from NASA data
        CASE 3 ' PLANET_JUPITER
            GetPlanetaryBindingEnergy = 2.06E+36 ' J - Calculated from NASA data
        CASE 4 ' PLANET_SATURN
            GetPlanetaryBindingEnergy = 2.22E+35 ' J - Calculated from NASA data
        CASE 5 ' PLANET_URANUS
            GetPlanetaryBindingEnergy = 1.19E+34 ' J - Calculated from NASA data
        CASE 6 ' PLANET_NEPTUNE
            GetPlanetaryBindingEnergy = 1.69E+34 ' J - Calculated from NASA data
        CASE 7 ' PLANET_PLUTO
            GetPlanetaryBindingEnergy = 2.85E+27 ' J - Calculated from NASA data
        CASE 8 ' PLANET_MOON
            GetPlanetaryBindingEnergy = 1.23E+29 ' J - Moon binding energy
        CASE 9 ' PLANET_VACUUM
            GetPlanetaryBindingEnergy = 2.49E+32 ' J - Default to Earth
        CASE ELSE
            GetPlanetaryBindingEnergy = 2.49E+32 ' J - Default to Earth
    END SELECT
END FUNCTION

FUNCTION GetPlanetType (planet_name AS STRING)
    ' Helper function to get planet type from string
    IF LEN(planet_name) = 0 THEN GetPlanetType = PLANET_EARTH: EXIT FUNCTION
    
    DIM pname AS STRING
    pname = UCASE$(planet_name)
    
    SELECT CASE pname
        CASE "EARTH"
            GetPlanetType = PLANET_EARTH
        CASE "MARS"
            GetPlanetType = PLANET_MARS
        CASE "VENUS"
            GetPlanetType = PLANET_VENUS
        CASE "JUPITER"
            GetPlanetType = PLANET_JUPITER
        CASE "SATURN"
            GetPlanetType = PLANET_SATURN
        CASE "URANUS"
            GetPlanetType = PLANET_URANUS
        CASE "NEPTUNE"
            GetPlanetType = PLANET_NEPTUNE
        CASE "PLUTO"
            GetPlanetType = PLANET_PLUTO
        CASE "MOON"
            GetPlanetType = PLANET_MOON
        CASE "VACUUM"
            GetPlanetType = PLANET_VACUUM
        CASE ELSE
            GetPlanetType = PLANET_EARTH ' default to Earth if unknown
    END SELECT
END FUNCTION

FUNCTION GetMaterialType (material_name AS STRING)
    ' Helper function to get material type from string
    IF LEN(material_name) = 0 THEN GetMaterialType = MATERIAL_STONY: EXIT FUNCTION
    
    DIM mname AS STRING
    mname = UCASE$(material_name)
    
    SELECT CASE mname
        CASE "IRON"
            GetMaterialType = MATERIAL_IRON
        CASE "COMETARY"
            GetMaterialType = MATERIAL_COMETARY
        CASE "STONY"
            GetMaterialType = MATERIAL_STONY
        CASE ELSE
            GetMaterialType = MATERIAL_STONY ' default to stony
    END SELECT
END FUNCTION

FUNCTION AtmosphericRetention (diameter_km AS DOUBLE, planet_type AS INTEGER, material_type AS INTEGER)
    ' Returns fraction of kinetic energy that reaches surface
    
    SELECT CASE planet_type
        CASE 0 ' PLANET_EARTH
            IF material_type = MATERIAL_IRON THEN ' Iron - higher survival rate
                IF diameter_km < 0.01 THEN AtmosphericRetention = 0.00 ' <10m: 0% retention
                IF diameter_km < 0.03 THEN AtmosphericRetention = 0.20 ' 10-30m: 20% retention
                IF diameter_km < 0.05 THEN AtmosphericRetention = 0.50 ' 30-50m: 50% retention
                IF diameter_km < 0.10 THEN AtmosphericRetention = 0.80 ' 50-100m: 80% retention
                IF diameter_km < 0.20 THEN AtmosphericRetention = 0.90 ' 100-200m: 90% retention
                AtmosphericRetention = 0.95 ' >200m: 95% retention
            ELSEIF material_type = MATERIAL_COMETARY THEN ' Cometary - very low survival
                IF diameter_km < 0.05 THEN AtmosphericRetention = 0.00 ' <50m: 0% retention
                IF diameter_km < 0.20 THEN AtmosphericRetention = 0.05 ' 50-200m: 5% retention
                AtmosphericRetention = 0.80 ' >200m: 80% retention
            ELSE ' Stony (default)
                IF diameter_km < 0.01 THEN AtmosphericRetention = 0.01 ' <10m: 1% retention
                IF diameter_km < 0.03 THEN AtmosphericRetention = 0.10 ' 10-30m: 10% retention
                IF diameter_km < 0.20 THEN AtmosphericRetention = 0.50 ' 30-200m: 50% retention
                AtmosphericRetention = 0.90 ' >200m: 90% retention
            END IF
        CASE 1 ' PLANET_MARS
            ' Mars: minimal atmospheric protection (1.3% of Earth's density)
            IF material_type = MATERIAL_IRON THEN ' Iron
                IF diameter_km < 0.001 THEN AtmosphericRetention = 0.80 ' <1m: 80% retention
                AtmosphericRetention = 0.95 ' >1m: 95% retention
            ELSEIF material_type = MATERIAL_COMETARY THEN ' Cometary
                IF diameter_km < 0.01 THEN AtmosphericRetention = 0.70 ' <10m: 70% retention
                AtmosphericRetention = 0.90 ' >10m: 90% retention
            ELSE ' Stony
                IF diameter_km < 0.005 THEN AtmosphericRetention = 0.85 ' <5m: 85% retention
                AtmosphericRetention = 0.95 ' >5m: 95% retention
            END IF
        CASE 2 ' PLANET_VENUS
            ' Venus: extreme atmospheric protection (53x denser than Earth)
            IF material_type = MATERIAL_IRON THEN ' Iron - best survival chance
                IF diameter_km < 0.10 THEN AtmosphericRetention = 0.00 ' <100m: 0% retention
                IF diameter_km < 0.50 THEN AtmosphericRetention = 0.10 ' 100-500m: 10% retention
                IF diameter_km < 1.00 THEN AtmosphericRetention = 0.50 ' 500m-1km: 50% retention
                AtmosphericRetention = 0.80 ' >1km: 80% retention
            ELSEIF material_type = MATERIAL_COMETARY THEN ' Cometary
                IF diameter_km < 1.00 THEN AtmosphericRetention = 0.00 ' <1km: 0% retention
                AtmosphericRetention = 0.30 ' >1km: 30% retention
            ELSE ' Stony
                IF diameter_km < 0.20 THEN AtmosphericRetention = 0.00 ' <200m: 0% retention
                IF diameter_km < 1.00 THEN AtmosphericRetention = 0.05 ' 200m-1km: 5% retention
                AtmosphericRetention = 0.60 ' >1km: 60% retention
            END IF
        CASE 3 ' PLANET_JUPITER
            ' Jupiter: massive atmospheric protection, crushing pressures
            IF material_type = MATERIAL_IRON THEN ' Iron
                IF diameter_km < 1.00 THEN AtmosphericRetention = 0.00 ' <1km: 0% retention
                IF diameter_km < 10.0 THEN AtmosphericRetention = 0.01 ' 1-10km: 1% retention
                AtmosphericRetention = 0.20 ' >10km: 20% retention
            ELSE ' Stony/Cometary - essentially no survival
                IF diameter_km < 10.0 THEN AtmosphericRetention = 0.00 ' <10km: 0% retention
                AtmosphericRetention = 0.10 ' >10km: 10% retention
            END IF
        CASE 8 ' PLANET_MOON
            ' Moon: essentially no atmosphere (3×10^-15 Pa vs Earth's 101,325 Pa)
            ' Extremely thin exosphere provides virtually no protection
            IF material_type = MATERIAL_IRON THEN ' Iron
                IF diameter_km < 0.001 THEN AtmosphericRetention = 0.99 ' <1m: 99% retention
                AtmosphericRetention = 1.00 ' >1m: 100% retention
            ELSEIF material_type = MATERIAL_COMETARY THEN ' Cometary
                IF diameter_km < 0.001 THEN AtmosphericRetention = 0.98 ' <1m: 98% retention
                AtmosphericRetention = 0.99 ' >1m: 99% retention
            ELSE ' Stony
                IF diameter_km < 0.001 THEN AtmosphericRetention = 0.99 ' <1m: 99% retention
                AtmosphericRetention = 1.00 ' >1m: 100% retention
            END IF
        CASE 9 ' PLANET_VACUUM
            AtmosphericRetention = 1.00 ' No atmospheric losses
        CASE ELSE
            AtmosphericRetention = 1.00 ' Default: no atmospheric losses for other planets
    END SELECT
END FUNCTION