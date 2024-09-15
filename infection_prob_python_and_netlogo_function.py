# imports
import numpy as np

#%% We want to compute p; Infection Probability for N Infected Adjacent Agents

# Read:
    # We calculate p for every agent of our map
    # To calculate, run the following functions. At the end, we care for compute_p
    # If it is computationally heavy, report and we'll figure out another solution
    # Parameters needed:
        # Masked : = 1 if masked, 0.5 if unmasked
        # N : number of infected agents inside a Euclidean radius of 2
        # distance : minimum Euclidean distance for the above N agents

# Infection Probability for 1 Infected Adjacent Agent
def compute_p0(masked, distance):
    power_factor = 0.75 * masked * (1-(1/(distance+1)))
    p0 = 0.60 - power_factor
    return p0

# Maximum Exponential Saturating Function for N Infected Adjacent Agents
def compute_pmax(N): 
    p_max = 0.90 - 0.4875 * np.exp(-0.3 * (N - 1))
    return p_max

# Infection Probability for N Infected Adjacent Agents
def compute_p(p0, p_max, N):
    p = p_max - 0.4125 + p0
    return p
#%% Scenario

N = 1 # Infected Agents within a Euclidean Radius of 2
min_distance = 2
masked = .5 # choose 1 if masked, 0.5 if unmasked

p0 = compute_p0(masked, min_distance)
p_max = compute_pmax(N)
p = compute_p(p0,p_max,N)
print(p)


#%% Syntax on NetLogo (?)

# You'll probably need an additional function that finds the amount of 
# INFECTED agents inside a radius of 2...

# Then calculate the minimum distance of these N agents... 
# eg. if  there are 3 Infected agents inside a radius=2, with distances 1, sqrt(2), and 2,
# then: distance = min(1,sqrt2,2)

# You might also need to store in each agent's state the masked attribute 
# (0.5 if unmasked) & (1 if masked)


# CODE ON NETLOGO:

# to-report compute-p0 [masked? distance]
#   let powerfactor 0.75 * masked? * (1 - (1 / (distance + 1)))
#   let p0 0.60 - powerfactor
#   report p0
# end

# to-report compute-pmax [N]
#   let pmax 0.90 - 0.4875 * exp (-0.3 * (N - 1))
#   report pmax
# end

# to-report compute-p [p0 pmax N]
#   let p pmax - 0.4125 + p0
#   report p
# end