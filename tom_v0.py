# compliance probability for 0th ToM agents
def default_strategy(I, R, C, H):
    if H == 1:
        p = 0.34*I + 0.33*(R * (100 - C)/100) + 0.33*C
    elif H == 0:
        p = 0.34*(-I) + 0.33*(R * (100 - C)/100) + 0.33*C
    elif H == 2:
        p = 0.5*(R * (100 - C)/100) + 0.5*C
    # normalize probability to be from 0 to 1
    normalized_p = (p + 100) / 200  # Shift and scale
    if H == 0:
        normalized_p = normalized_p + 0.15
    # the formula makes sure probability is within 0 to 1 (to be sure)
    return min(1, max(0, normalized_p))

# compute other agents' average compliance probability
def average_compliance_prob(I, R, C):
    ## other infected and healthy agents on the grid
    # Ratio of infected agents in grid
    other_H0 = 0.01*I 
    # Ratio of healthy agents in grid
    other_H1 = 0.01*(100 - I)
    # Compliance estimation of infected agents
    other_H0_compliance_prob =  default_strategy(I, R, C, H=0)
    # Compliance estimation of healthy agents
    other_H1_compliance_prob =  default_strategy(I, R, C, H=1)
    # Compliance probability of average agent
    other_compliance_prob = other_H0 * other_H0_compliance_prob + other_H1 * other_H1_compliance_prob
    # the formula makes sure probability is within 0 to 1
    return min(1, max(0, other_compliance_prob))

# compliance probability for 1st ToM agents
def tom1(I, R, C, H):
    ## 1st order ToM agent ignores immune agents and strategizes based on reasoning about
    other_compliance_prob = average_compliance_prob(I, R, C)
    # Multiply probability by a 100 to make this %
    other_compliance_prob = other_compliance_prob * 100
    # Reason about compliance based on the agent's own health status
    if H == 1:
        p = 0.25*I + 0.25*(R * (100 - C)/100) + 0.5*(100-other_compliance_prob)
    elif H == 0:
        p = 0.25*(-I) + 0.25*(R * (100 - C)/100) + 0.5*(100-other_compliance_prob)
    elif H == 2:
        p = 0.5*(R * (100 - C)/100) + 0.5*C # do we include others' compliance for the immune?
    # normalize probability to be from 0 to 1
    normalized_p = (p + 100) / 200
    # the formula makes sure probability is within 0 to 1 (to be sure)
    return min(1, max(0, normalized_p))

#%% Imports

import numpy as np
import matplotlib.pyplot as plt


#%% Plot 0-th order ToM Compliance Probabilities

# Define ranges for I, R, C
I_values = np.linspace(0, 100, 100) 
R_values = np.linspace(0, 100, 100)  
C_values = np.linspace(0, 100, 100)   

I_grid, R_grid = np.meshgrid(I_values, R_values)
# Prepare arrays to store the results for H=0, H=1, and H=2
output_H0 = np.zeros_like(I_grid)
output_H1 = np.zeros_like(I_grid)
output_H2 = np.zeros_like(I_grid)
# Calculate the strategy values for H=0, H=1, and H=2
C = 0.5
for i in range(I_grid.shape[0]):
    for j in range(I_grid.shape[1]):
        I = I_grid[i, j]
        R = R_grid[i, j]
        output_H0[i, j] = default_strategy(I, R, C, H=0)
        output_H1[i, j] = default_strategy(I, R, C, H=1)
        output_H2[i, j] = default_strategy(I, R, C, H=2)

# Plotting in 3D
fig = plt.figure(figsize=(29, 20))
# Plot for H=0 (infected)
ax1 = fig.add_subplot(131, projection='3d')
ax1.plot_surface(I_grid, R_grid, output_H0, cmap='summer')
ax1.set_title('H=0 (Infected Agent)')
ax1.set_xlabel('I (Infection Percentage)')
ax1.set_ylabel('R (Regulation Strictness)')
ax1.set_zlabel('Compliance Probability')
# Plot for H=1 (healthy)
ax2 = fig.add_subplot(132, projection='3d')
ax2.plot_surface(I_grid, R_grid, output_H1, cmap='summer')
ax2.set_title('H=1 (Healthy Agent)')  # Corrected title
ax2.set_xlabel('I (Infection Percentage)')
ax2.set_ylabel('R (Regulation Strictness)')
ax2.set_zlabel('Compliance Probability')
# Plot for H=2 (immune)
ax3 = fig.add_subplot(133, projection='3d')
ax3.plot_surface(I_grid, R_grid, output_H2, cmap='summer')
ax3.set_title('H=2 (Immune Agent)')  # Corrected title
ax3.set_xlabel('I (Infection Percentage)')
ax3.set_ylabel('R (Regulation Strictness)')
ax3.set_zlabel('Compliance Probability')
plt.tight_layout()
plt.show()


#%% Plot 1-st order ToM Compliance Probabilities

# Define ranges for I, R, C
I_values = np.linspace(0, 100, 100) 
R_values = np.linspace(0, 100, 100)  
C_values = np.linspace(0, 100, 100)   

I_grid, R_grid = np.meshgrid(I_values, R_values)
# Prepare arrays to store the results for H=0, H=1, and H=2
output_H0 = np.zeros_like(I_grid)
output_H1 = np.zeros_like(I_grid)
output_H2 = np.zeros_like(I_grid)
# Calculate the strategy values for H=0, H=1, and H=2
C = 0.5
for i in range(I_grid.shape[0]):
    for j in range(I_grid.shape[1]):
        I = I_grid[i, j]
        R = R_grid[i, j]
        output_H0[i, j] = tom1(I, R, C, H=0)
        output_H1[i, j] = tom1(I, R, C, H=1)
        output_H2[i, j] = tom1(I, R, C, H=2)

# Plotting in 3D
fig = plt.figure(figsize=(29, 20))
# Plot for H=0 (infected)
ax1 = fig.add_subplot(131, projection='3d')
ax1.plot_surface(I_grid, R_grid, output_H0, cmap='summer')
ax1.set_title('H=0 (Infected Agent)')
ax1.set_xlabel('I (Infection Percentage)')
ax1.set_ylabel('R (Regulation Strictness)')
ax1.set_zlabel('Compliance Probability')
# Plot for H=1 (healthy)
ax2 = fig.add_subplot(132, projection='3d')
ax2.plot_surface(I_grid, R_grid, output_H1, cmap='summer')
ax2.set_title('H=1 (Healthy Agent)')  # Corrected title
ax2.set_xlabel('I (Infection Percentage)')
ax2.set_ylabel('R (Regulation Strictness)')
ax2.set_zlabel('Compliance Probability')
# Plot for H=2 (immune)
ax3 = fig.add_subplot(133, projection='3d')
ax3.plot_surface(I_grid, R_grid, output_H2, cmap='summer')
ax3.set_title('H=2 (Immune Agent)')  # Corrected title
ax3.set_xlabel('I (Infection Percentage)')
ax3.set_ylabel('R (Regulation Strictness)')
ax3.set_zlabel('Compliance Probability')
plt.tight_layout()
plt.show()


