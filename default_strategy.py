# I is % infected agents
# H is health-status (0 if infected or immune, 1 if healthy)
# R is Regulation Strictness
# C is willingness to comply


# THIS FUNCTION GENERATES THE PROBABILITY OF COMPLIANCE (OUTPUT RANGES FROM 0 TO 1)
def default_strategy(I, R, C, H):
    if H == 1:
        p = 0.34*I + 0.33*(R * (100 - C)/100) + 0.33*C
    elif H == 0:
        p = 0.34*(-I) + 0.33*(R * (100 - C)/100) + 0.33*C
    normalized_p = (p + 100) / 200  # Shift and scale
    return normalized_p

# pick a random number in [0,1] for each agent
# if random number < default_strategy output -> agent complies
# else if random number > default_strategy output -> agent does not comply