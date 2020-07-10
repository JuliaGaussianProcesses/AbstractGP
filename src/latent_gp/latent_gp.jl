"""
    LatentGP(f<:GP, lik, Σy)

 - `f` is a `AbstractGP`.
 - `lik` is the log likelihood function which maps sample from f to corresposing 
 conditional likelihood distributions.
 - `Σy` is the observation noise
    
"""
struct LatentGP{T<:AbstractGPs.AbstractGP,S,E}
    f::T
    lik::S
    Σy::E
end


"""
    LatentFiniteGP(fx<:FiniteGP, lik)

 - `fx` is a `FiniteGP`.
 - `lik` is the log likelihood function which maps sample from f to corresposing 
 conditional likelihood distributions.
    
"""
struct LatentFiniteGP{T<:AbstractGPs.FiniteGP,S}
    fx::T
    lik::S
end

(lgp::LatentGP)(x) = LatentFiniteGP(lgp.f(x, lgp.Σy), lgp.lik)

function Distributions.rand(rng::AbstractRNG, lfgp::LatentFiniteGP)
    f = rand(rng, lfgp.fx)
    y = rand(rng, lfgp.lik(f))
    return (f=f, y=y)
end

"""
    logpdf(lfgp::LatentFiniteGP, y::NamedTuple{(:f, :y)})

```math
    log p(y, f; x)
```
Returns the joint log density of the gaussian process output `f` and real output `y`.
"""
function Distributions.logpdf(lfgp::LatentFiniteGP, y::NamedTuple{(:f, :y)})
    return logpdf(lfgp.fx, y.f) + logpdf(lfgp.lik(y.f), y.y)
end
