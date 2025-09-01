$CONSOLE:ONLY
'----------------------------------------------------------------
' unbindDose.bas
' (C) 2025 - George McGinn - MIT License
' Compute the upper and lower bound lunar dose from Earth destruction impact in Grays
' Build: Run in QB64 or QB64PE environment
' Comile: qb64pe -x /path/to/unbindDose.bas -o /path/to/unbindDose
'
' Usage:
'   unbindDose [E=2.49e32] [eta=3e-3] [d=3.844e8] [A=0.7] [M=70.0] [f=1.0] [theta_deg=75.0]
'
' Examples:
'   unbindDose
'   unbindDose 2.49e32 3e-3 3.844e8 0.7 70 1 75
' 
' Where:
'  - E = total energy (J) released by Earth destruction
'  - eta = fraction of E emitted as radiation (3e-3 is ~nuclear explosion fraction)
'  - d = distance to Moon (m) (3.844e8 m is average Earth-Moon distance)
'  - A = fraction of radiation absorbed by body (0.7 is typical for human tissue)
'  - M = mass of body (kg) (70 kg is typical adult human mass)         
'  - f = fraction of body exposed to radiation (1.0 is full exposure)
'  - theta_deg = angle of incidence (degrees) (75 degrees is glancing blow)
'
' Notes:        
'  - Outputs dose in Grays (Gy = J/kg)
'  - Upper boundary dose assumes direct overhead exposure (max exposure)
'  - Lower boundary dose assumes angle theta_deg from vertical (glancing blow)      
'  - This is a simplified model with basic atmospheric attenuation but does not account 
'    for energy-dependent absorption, radiation type differences, secondary radiation, etc.
'  - 8 Gy is a lethal dose for humans (without medical treatment)
'  - Dose = (fluence * A * f * cos(theta)) / M
'           where fluence = (eta * E) / (4 * pi * d^2) (J/m^2)  
'  - cos(theta) = cosine of angle of incidence (1.0 for upper boundary, cos(theta_deg) for lower boundary)      
'----------------------------------------------------------------

' Parse command line arguments
DIM cmd           AS STRING
DIM args(1 TO 10) AS STRING
DIM arg_count     AS INTEGER

cmd = COMMAND$
arg_count = 0

' Simple argument parsing
IF LEN(cmd) > 0 THEN
    DIM temp AS STRING
    DIM i    AS INTEGER
    temp = cmd + " "
    i = 1
    WHILE i <= LEN(temp)
        IF MID$(temp,     PRINTi, 1) <> " " THEN
            arg_count = arg_count + 1
            WHILE i <= LEN(temp) AND MID$(temp, i, 1) <> " "
                args(arg_count) = args(arg_count) + MID$(temp, i, 1)
                i = i + 1
            WEND
        END IF
        i = i + 1
    WEND
END IF

' Set default values or parse from command line
DIM E           AS DOUBLE
DIM eta         AS DOUBLE
DIM distance    AS DOUBLE
DIM absorb      AS DOUBLE
DIM mass        AS DOUBLE
DIM body_frac   AS DOUBLE
DIM theta_deg   AS DOUBLE
DIM atmos_trans AS DOUBLE

' Parse arguments or set defaults
IF arg_count >= 1 THEN E = VAL(args(1)) ELSE E = 2.49E+32
IF arg_count >= 2 THEN eta = VAL(args(2)) ELSE eta = 3E-3
IF arg_count >= 3 THEN distance = VAL(args(3)) ELSE distance = 3.844E+8
IF arg_count >= 4 THEN absorb = VAL(args(4)) ELSE absorb = 0.7
IF arg_count >= 5 THEN mass = VAL(args(5)) ELSE mass = 70.0
IF arg_count >= 6 THEN body_frac = VAL(args(6)) ELSE body_frac = 1.0
IF arg_count >= 7 THEN theta_deg = VAL(args(7)) ELSE theta_deg = 75.0
IF arg_count >= 8 THEN atmos_trans = VAL(args(8)) ELSE atmos_trans = 1.0

' Calculate fluence and doses
DIM cos_theta    AS DOUBLE
DIM fluence      AS DOUBLE
DIM D_upper      AS DOUBLE
DIM D_lower      AS DOUBLE
DIM f_attenuated AS DOUBLE

cos_theta = COS(theta_deg * _PI / 180.0)
fluence = eta * E / (4.0 * _PI * distance * distance)

f_attenuated = fluence * atmos_trans
D_upper = calc_dose#(f_attenuated, absorb, body_frac, mass, 1.0)
D_lower = calc_dose#(f_attenuated, absorb, body_frac, mass, cos_theta)

PRINT "Impact Generated Radiation Dose"
PRINT "-------------------------------"
PRINT
PRINT "Fluence = "; : PRINT USING "##.######^^^^"; fluence; : PRINT " J/m^2"
PRINT
PRINT "Dose (upper boundary, max exposure) = "; : PRINT USING "##.######^^^^"; D_upper; : PRINT " Gy"
IF D_upper > 8 THEN
    PRINT "*** WARNING: Dose exceeds 8 Gy (lethal dose for humans)"
    PRINT
END IF
PRINT "Dose (lower boundary, angle "; : PRINT USING "##.#"; theta_deg; : PRINT " deg, glancing blow) = "; : PRINT USING "##.######^^^^"; D_lower; : PRINT " Gy"
IF D_lower > 8 THEN
    PRINT "*** WARNING: Dose exceeds 8 Gy (lethal dose for humans)"
END IF
PRINT

SYSTEM 0

FUNCTION calc_dose# (fluence AS DOUBLE, absorb AS DOUBLE, body_frac AS DOUBLE, mass AS DOUBLE, cos_theta AS DOUBLE)
         calc_dose# = (fluence * absorb * body_frac * cos_theta) / mass
END FUNCTION
