import numpy as np
import matplotlib.pyplot as plt

# Does the agent wear a mask? - Mask Factor
mask = [1,0.5]
# What's the distance with another agent?
dist = [2,np.sqrt(2),1]

# Compute Distance Factor
dist_factor = []
for _,d in enumerate(dist):
    dist_factor.append(1-(1/(d+1)))
base = 0.75


# Compute Overall Power Factor & Fill the plot labels
factor=[]
labels=[]
for _,i in enumerate(mask):
    for dj,j in enumerate(dist_factor):
        factor.append(base*i*j)
        if i == 1:
            labels.append("Masked | Distance = "+str(round(dist[dj],2)))
        else:
            labels.append("Unmasked | Distance = "+str(round(dist[dj],2)))

# Compute Probability
prob = []
for _,f in enumerate(factor):
    prob.append(0.60-f)


#%% Display Curve Family

# Number of Adjacent Agents (distance<=2)
x = np.arange(1, 12)

# Curve Parameters
p1 = 0.90 # highest possibility in worst scenario of getting infected (convergence point)
p0 = max(prob) # starting point of worst possible curve
k = 0.3  # Controls the rate of saturation

# Exponential saturating function starting at p0 and saturating at p1 - Worst possible curve
fun = p1 - (p1 - p0) * np.exp(-k * (x - x[0]))

# All curves for different initial probabilities of infection
curves=[]
for _,p in enumerate(prob):
    curves.append(fun - (p0 - p))

# Labels for all curves:


# Plot to visualize
plt.figure()
for i in range(len(curves)):
    plt.plot(x, curves[i], marker='o', label = labels[i])
plt.title('Infection Probability Scenarios')
plt.xlabel('Number of Infected Adjacent Agents')
plt.ylabel('Probability of Infection')
plt.legend()
plt.grid(True)
plt.show()

#%% Scenario: An Unmasked agent and has 3 adjacent, infected agents in distances 1, 2, and 2. 
# What is the probability of getting infected?

K = 3 # number of adjacent agents
adjacent_agent_distances = [1,2,2]
mask_factor = .5

base_factor = 0.75 #fixed
diff = 0.40 #fixed

distance = np.min(adjacent_agent_distances)
dist_factor = 1-(1/(distance+1))

# Power Factor and Infection Probability for a single adjacent agent
overall_factor = base_factor * mask_factor * dist_factor
infection_prob = 0.60-overall_factor

# Infection Probability for 3 adjacent agents
total_infection_prob = (fun - p0 + infection_prob)[K-1]
