"""
    LatentGP(f<:GP, lik, Σy)

 - `f` is a `AbstractGP`.
 - `lik` is the log likelihood function which maps samples from `f` to the corresponding 
 conditional likelihood distributions.
 - `Σy` is the observation noise; this represents the jitter used to avoid numeric instability and should generally be small.
    
"""
struct LatentGP{Tf<:AbstractGP,Tlik,TΣy}
    f::Tf
    lik::Tlik
    Σy::TΣy
end

"""
    LatentFiniteGP(fx<:FiniteGP, lik)

 - `fx` is a `FiniteGP`.
 - `lik` is the log likelihood function which maps samples from `f` to the corresponding 
 conditional likelihood distributions.
    
"""
struct LatentFiniteGP{Tfx<:FiniteGP,Tlik}
    fx::Tfx
    lik::Tlik
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
The joint log density of the Gaussian process output `f` and observation `y`.
"""
function Distributions.logpdf(lfgp::LatentFiniteGP, y::NamedTuple{(:f, :y)})
    return logpdf(lfgp.fx, y.f) + logpdf(lfgp.lik(y.f), y.y)
end
