# Retrieve name of example and output directory
if length(ARGS) != 2
    error("please specify the name of the example and the output directory")
end
const EXAMPLE = ARGS[1]
const OUTDIR = abspath(ARGS[2])

# Activate environment
# Note that each example's Project.toml must include Literate as a dependency
using Pkg: Pkg
const EXAMPLEPATH = joinpath(@__DIR__, "..", "examples", EXAMPLE)
Pkg.activate(EXAMPLEPATH)
Pkg.instantiate()
using Literate: Literate

function preprocess(content)
    # Add link to nbviewer below the first heading of level 1
    sub = SubstitutionString(
        """
#md # ```@meta
#md # EditURL = "@__REPO_ROOT_URL__/examples/@__NAME__/script.jl"
#md # ```
#md #
\\0
#
#md # [![](https://img.shields.io/badge/show-nbviewer-579ACA.svg)](@__NBVIEWER_ROOT_URL__/examples/@__NAME__.ipynb)
#md #
# *You are seeing the
#md # HTML output generated by [Documenter.jl](https://github.com/JuliaDocs/Documenter.jl) and
#nb # notebook output generated by
# [Literate.jl](https://github.com/fredrikekre/Literate.jl) from the
# [Julia source file](@__REPO_ROOT_URL__/examples/@__NAME__/script.jl).
#md # The corresponding notebook can be viewed in [nbviewer](@__NBVIEWER_ROOT_URL__/examples/@__NAME__.ipynb).*
#nb # The rendered HTML can be viewed [in the docs](https://juliagaussianprocesses.github.io/AbstractGPs.jl/dev/examples/@__NAME__/).*
#
        """,
    )
    content = replace(content, r"^# # [^\n]*"m => sub; count=1)

    # remove VSCode `##` block delimiter lines
    content = replace(content, r"^##$."ms => "")

    # remove JuliaFormatter commands
    content = replace(content, r"^#! format: off$."ms => "")
    content = replace(content, r"^#! format: on$."ms => "")

    # When run through Literate, the actual @__DIR__ macro points to the OUTDIR
    # Instead, replace it with the directory in which the script itself is located:
    content = replace(content, r"@__DIR__" => "\"$(escape_string(EXAMPLEPATH))\"")

    return content
end

# Convert to markdown and notebook
const SCRIPTJL = joinpath(EXAMPLEPATH, "script.jl")
Literate.markdown(
    SCRIPTJL, OUTDIR; name=EXAMPLE, documenter=true, execute=true, preprocess=preprocess
)
Literate.notebook(
    SCRIPTJL, OUTDIR; name=EXAMPLE, documenter=true, execute=true, preprocess=preprocess
)
