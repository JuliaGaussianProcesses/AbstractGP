struct VFE end
const DTC = VFE

struct ApproxPosteriorGP{Tapprox, Tprior, Tdata} <: AbstractGP
    approx::Tapprox
    prior::Tprior
    data::Tdata
end

"""
    approx_posterior(::VFE, fx::FiniteGP, y::AbstractVector{<:Real}, u::FiniteGP)

Compute the optimal approximate posterior [1] over the process `f`, given observations `y`
of `f` at `x`, and inducing points `u`, where `u = f(z)` for some inducing inputs `z`.

[1] - M. K. Titsias. "Variational learning of inducing variables in sparse Gaussian
processes". In: Proceedings of the Twelfth International Conference on Artificial
Intelligence and Statistics. 2009.
"""
function approx_posterior(::VFE, fx::FiniteGP, y::AbstractVector{<:Real}, u::FiniteGP)
    U_y = cholesky(Symmetric(fx.Σy)).U
    U = cholesky(Symmetric(cov(u))).U
    B_εf = U' \ (U_y' \ cov(fx, u))'
    b_y = U_y' \ (y - mean(fx))
    D = B_εf * B_εf' + I
    Λ_ε = cholesky(Symmetric(D))
    m_ε = Λ_ε \ (B_εf * b_y)
    return ApproxPosteriorGP(VFE(), fx.f,
                             (m_ε=m_ε,
                              Λ_ε=Λ_ε,
                              U=U,
                              α=U \ m_ε,
                              z=u.x,
                              b_y=b_y,
                              B_εf=B_εf,
                              D=D,
                              x=fx.x,
                              Σy=fx.Σy,
                              ))
end

"""
    update_approx_posterior(f_post_approx::ApproxPosteriorGP,
                            fx::FiniteGP,
                            y::AbstractVector{<:Real})

#TODO

"""
function update_approx_posterior(f_post_approx::ApproxPosteriorGP,
                                 fx::FiniteGP,
                                 y::AbstractVector{<:Real})
    U_y₂ = cholesky(Symmetric(fx.Σy)).U
    temp = zeros(size(f_post_approx.data.Σy, 1), size(fx.Σy, 2))
    Σy = [f_post_approx.data.Σy temp; temp' fx.Σy]
    b_y = vcat(f_post_approx.data.b_y, U_y₂ \ (y - mean(fx)))
    U = f_post_approx.data.U
    z = f_post_approx.data.z
    B_εf₂ = U' \ (U_y₂' \ cov(fx.f, fx.x, z))'
    B_εf = hcat(f_post_approx.data.B_εf, B_εf₂)
    D = f_post_approx.data.D +  B_εf₂ * B_εf₂'
    Λ_ε = cholesky(Symmetric(D))
    m_ε = Λ_ε \ (B_εf * b_y)
    α = U \ m_ε
    x = vcat(f_post_approx.data.x, fx.x)
    return ApproxPosteriorGP(VFE(), fx.f,
                             (m_ε=m_ε,
                              Λ_ε=Λ_ε,
                              U=U,
                              α=α,
                              z=z,
                              b_y=b_y,
                              B_εf=B_εf,
                              D=D,
                              x=x,
                              Σy=Σy,
                              ))
end

function update_approx_posterior(f_post_approx::ApproxPosteriorGP,
                                 u::FiniteGP)
    U11 = f_post_approx.data.U
    C12 = cov(u.f, f_post_approx.data.z, u.x)
    C22 = Symmetric(cov(u))
    U = update_chol(Cholesky(U11,'U', 0), C12, C22).U
    U22 = U[end-length(u)+1:end, end-length(u)+1:end]
    U12 = U[1:length(f_post_approx.data.z), end-length(u)+1:end]
    B_εf₁ = f_post_approx.data.B_εf
    Cu1f = cov(f_post_approx.prior, f_post_approx.data.z, f_post_approx.data.x)
    Cu2f = cov(f_post_approx.prior, u.x, f_post_approx.data.x)
    U_y = cholesky(Symmetric(f_post_approx.data.Σy)).U
    B_εf₂ = U22' \ (Cu2f * inv(U_y)   - U12' * B_εf₁)
    B_εf = vcat(B_εf₁, B_εf₂)
    Λ_ε = update_chol(f_post_approx.data.Λ_ε, B_εf₁ * B_εf₂', B_εf₂ * B_εf₂' + I)
    m_ε = Λ_ε \ (B_εf * f_post_approx.data.b_y)
    α = U \ m_ε
    z = vcat(f_post_approx.data.z, u.x)
    return ApproxPosteriorGP(VFE(), f_post_approx.prior,
                             (
                              m_ε=m_ε,
                              Λ_ε=Λ_ε,
                              U=U,
                              α=α,
                              z=z,
                              b_y=f_post_approx.data.b_y,
                              B_εf=B_εf,
                              D=Λ_ε.U' * Λ_ε.U,
                              x=f_post_approx.data.x,
                              Σy=f_post_approx.data.Σy,   
                             ))
end
# Blatant act of type piracy against LinearAlgebra.
LinearAlgebra.Symmetric(X::Diagonal) = X

# AbstractGP interface implementation.

function Statistics.mean(f::ApproxPosteriorGP{VFE}, x::AbstractVector)
    return mean(f.prior, x) + cov(f.prior, x, f.data.z) * f.data.α
end

function Statistics.cov(f::ApproxPosteriorGP{VFE}, x::AbstractVector)
    A = f.data.U' \ cov(f.prior, f.data.z, x)
    return cov(f.prior, x) - At_A(A) + Xt_invA_X(f.data.Λ_ε, A)
end

function cov_diag(f::ApproxPosteriorGP{VFE}, x::AbstractVector)
    A = f.data.U' \ cov(f.prior, f.data.z, x)
    return cov_diag(f.prior, x) - diag_At_A(A) + diag_Xt_invA_X(f.data.Λ_ε, A)
end

function Statistics.cov(f::ApproxPosteriorGP{VFE}, x::AbstractVector, y::AbstractVector)
    A_zx = f.data.U' \ cov(f.prior, f.data.z, x)
    A_zy = f.data.U' \ cov(f.prior, f.data.z, y)
    return cov(f.prior, x, y) - A_zx'A_zy + Xt_invA_Y(A_zx, f.data.Λ_ε, A_zy)
end

function mean_and_cov(f::ApproxPosteriorGP{VFE}, x::AbstractVector)
    A = f.data.U' \ cov(f.prior, f.data.z, x)
    m_post = mean(f.prior, x) + A' * f.data.m_ε
    C_post = cov(f.prior, x) - At_A(A) + Xt_invA_X(f.data.Λ_ε, A)
    return m_post, C_post
end

function mean_and_cov_diag(f::ApproxPosteriorGP{VFE}, x::AbstractVector)
    A = f.data.U' \ cov(f.prior, f.data.z, x)
    m_post = mean(f.prior, x) + A' * f.data.m_ε
    c_post = cov_diag(f.prior, x) - diag_At_A(A) + diag_Xt_invA_X(f.data.Λ_ε, A)
    return m_post, c_post
end
