module AbstractGPs

using ChainRulesCore
using Distributions
using FillArrays
using LinearAlgebra
using Reexport
@reexport using KernelFunctions
using Random
using Statistics
using StatsBase
using RecipesBase

using KernelFunctions: ColVecs, RowVecs

export GP,
    rand!,
    mean,
    cov,
    var,
    std,
    mean_and_cov,
    mean_and_var,
    marginals,
    logpdf,
    elbo,
    dtc,
    posterior,
    approx_posterior,
    VFE,
    DTC,
    update_approx_posterior,
    LatentGP,
    ColVecs,
    RowVecs

# Various bits of utility functionality.
include(joinpath("util", "common_covmat_ops.jl"))

# AbstractGP interface.
include("abstract_gp.jl")

# FiniteGP object that describes the projection of a GP at points x.
include("finite_gp_projection.jl")

# Basic GP object, e.g. to define the prior.
include("mean_function.jl")
include("base_gp.jl")

# Efficient exact posterior GP implementation.
include("exact_gpr_posterior.jl")

# Approximate sparse GP inference for Gaussian likelihood.
include("sparse_approximations.jl")

# LatentGP and LatentFiniteGP objects to accommodate GPs with non-Gaussian likelihoods.
include("latent_gp.jl")

# Plotting utilities.
include(joinpath("util", "plotting.jl"))

# Testing utilities.
include(joinpath("util", "test_util.jl"))

# Deprecations.
include("deprecations.jl")

end # module
