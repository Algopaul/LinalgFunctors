using LinearAlgebra
using KWLinalg
using Test
using Random

@testset "LU-Updates" begin
    for n in [1, 10]
        m = max(n - 2, 1) # Choose rectangular RHS
        A = rand(MersenneTwister(0), n, n)
        AC = deepcopy(A)
        A2 = rand(MersenneTwister(1), n, n)
        B = rand(MersenneTwister(2), n, m)
        X = rand(MersenneTwister(3), n, m)
        lu_D = lu!(A2)
        A2 .= AC
        LAPACK.getrf!(lu_D.factors, lu_D.ipiv)
        ldiv_alloc = @allocated ldiv!(X, lu_D, B)
        @test ldiv_alloc == 0
        @test norm(X - A \ B) < 1e-16
        A2 .= AC
        getrf_alloc = @allocated LAPACK.getrf!(lu_D.factors, lu_D.ipiv)
        # Upon second call, no memory should be allocated.
        @test getrf_alloc == 0
    end
end

function test_svd_functor(m, n, fun, alg, ele)
    A = rand(MersenneTwister(0), typeof(ele), m, n)
    AC = deepcopy(A)
    svd_functor = fun(m, n)
    U, S, V = svd_functor(A)
    U2, S2, V2 = svd!(AC, alg = alg)
    @test norm(U - U2) == 0.0
    @test norm(S - S2) == 0.0
    @test norm(V - V2) == 0.0
    A = rand(MersenneTwister(0), typeof(ele), m, n)
    svd_alloc = @allocated svd_functor(A)
    # Upon second call, no memory should be allocated.
    @test svd_alloc == 0
    return nothing
end

@testset "Complex SVD" begin
    for n in [1, 10]
        for m in [1, 10]
            for (fun, alg, dtype) in [
                (svd_divconquer_cf64, LinearAlgebra.DivideAndConquer(), ComplexF64),
                (svd_divconquer_cf32, LinearAlgebra.DivideAndConquer(), ComplexF32),
                (svd_qr_cf64, LinearAlgebra.QRIteration(), ComplexF64),
                (svd_qr_cf32, LinearAlgebra.QRIteration(), ComplexF32),
                (svd_divconquer_f64, LinearAlgebra.DivideAndConquer(), Float64),
                (svd_divconquer_f32, LinearAlgebra.DivideAndConquer(), Float32),
                (svd_qr_f64, LinearAlgebra.QRIteration(), Float64),
                (svd_qr_f32, LinearAlgebra.QRIteration(), Float32),
            ]
                test_svd_functor(m, n, fun, alg, one(dtype))
            end
        end
    end
end
