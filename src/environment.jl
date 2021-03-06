#=
  Package: FishEBM
  File name: environment.jl
  Devin Rose
  Generates an abstracted environment environment agent interaction from known
    bathymetry data.
  Created: March, 2016
=#


"""
  Description: Generates a hash map to reference agent numbers from known
    spawning and risk spatial locations. i.e. e_a.spawning[someNum] =
    (a_db[e_a.spawningHash[sumNum]]).locationID

  Returns: Operates directly on enviro

  Last update: September 2016
"""
function hashEnvironment!(a_db::Vector{EnviroAgent}, enviro::EnvironmentAssumptions)
  #Initialize required variables
  totalAgents = length(a_db)

  #map spawning and risk identities to agent numbers
  for agent = 1:totalAgents
    riskNum = findfirst(enviro.risk, (a_db[agent]).locationID)
    if riskNum != 0
      enviro.riskHash[riskNum] = agent
    end

    spawnNum = findfirst(enviro.spawning, (a_db[agent]).locationID)
    if spawnNum != 0
      enviro.spawningHash[spawnNum] = agent
    end

    harvestNum = findfirst(enviro.abstractHarvest, (a_db[agent]).locationID)
    if harvestNum != 0
      enviro.harvestHash[harvestNum] = agent
    end
  end
end


"""
  Description: Generates an environment for the simulation. Both the risk
    assessment and spawning environments are abstracted to a list of integer
    values.

  Returns: EnvironmentAssumptions

  Last update: September 2016
"""
function initEnvironment(pathToSpawn::String, pathToHabitat::String, pathToRisk::String, pathToHarvest::String)
  #Pad all incoming arrays
  spawn = readdlm(pathToSpawn, ',', Bool)[150:end, 200:370]; pad_environment!(spawn)
  habitat = readdlm(pathToHabitat, ',', Int)[150:end, 200:370]; pad_environment!(habitat)
  risk = readdlm(pathToRisk, ',', Bool)[150:end, 200:370]; pad_environment!(risk)
  harvest = readdlm(pathToHarvest, ',', Int)[150:end, 200:370]; pad_environment!(harvest)

  @assert(size(habitat)[1] == size(harvest)[1] && size(habitat)[2] == size(harvest)[2], "Harvest areas must match habitat areas!")

  totalLength = (size(spawn)[1])*(size(spawn)[2])

  # Initialize abstract vectors
  abstractSpawn = [0]; abstractRisk = [0]; abstractHarvest = [0]; harvestZones = [0];

  # Generate a hashmap for applicable environment properties
  for index = 1:totalLength
    # Hash spawning locations
    if spawn[index] == true
      if abstractSpawn[1] == 0
        abstractSpawn[1] = index
      else
        push!(abstractSpawn, index)
      end
    end

    # Hash risk locations
    if risk[index] == true
      if abstractRisk[1] == 0
        abstractRisk[1] = index
      else
        push!(abstractRisk, index)
      end
    end

    # Hash harvest locations, and zone numbers
    if harvest[index] != 0 && habitat[index] > 0
      if abstractHarvest[1] == 0
        abstractHarvest[1] = index
        harvestZones[1] = harvest[index]
      else
        push!(abstractHarvest, index)
        push!(harvestZones, harvest[index])
      end #if abstractHarvest
    end #if harvest
  end

  # Allocate enough memory for hash environment variables
  hashingSpawn = fill(0, length(abstractSpawn))
  hashingRisk = fill(0, length(abstractRisk))
  hashingHarvest = fill(0, length(harvestZones))

  e_a = EnvironmentAssumptions(abstractSpawn, hashingSpawn,
    habitat,
    abstractRisk, hashingRisk,
    harvest, abstractHarvest, harvestZones, hashingHarvest)

  return e_a
end


"""
  Description: Generates an environment for the simulation. Container function
    for the other initEnvironment for simplicity.

  Returns: EnvironmentAssumptions

  Last update: June 2016
"""
function initEnvironment()
  spawnPath = string(split(Base.source_path(), "FishEBM.jl")[1], "FishEBM.jl/maps/LakeHuron_1km_spawning.csv")
  habitatPath = string(split(Base.source_path(), "FishEBM.jl")[1], "FishEBM.jl/maps/LakeHuron_1km_habitat.csv")
  riskPath = string(split(Base.source_path(), "FishEBM.jl")[1], "FishEBM.jl/maps/LakeHuron_1km_risk.csv")

  return initEnvironment(spawnPath, habitatPath, riskPath)
end


"""
  Description: Checks all cohorts within an enviro-agent to determine whether or
    not the enviroment location contains any agents.

  Returns: Boolean

  Last update: May 2016
"""
function isEmpty(empty_check::EnviroAgent)
  #check length of vector
  for i = 1:length(empty_check.alive)
    #if agents are in the location
    if empty_check.alive[i] != 0
      return false
    end
  end

  #if no agents are found, function returns true
  return true
end


"""
  Taken from FishABM.utilities.jl

  Description: A basic utility function which will pad the
    EnvironmentAssumptions such that bounds errors do not occur when performing
    hashing and movement.

  Retruns: Array

  Updated: June 2016
"""
function pad_environment!(pad_array::Array)
  a = fill(0, (size(pad_array, 1)+2, size(pad_array, 2)+2))
  a[2:end-1, 2:end-1] = pad_array
  pad_array = a
end
