round(x::ArbFloat{P}, ::RoundingMode{:Up}) where {P} = ceil(x)
round(x::ArbFloat{P}, ::RoundingMode{:Down}) where {P} = floor(x)
round(x::ArbFloat{P}, ::RoundingMode{:ToZero}) where {P} = signbit(x) ? ceil(x) : floor(x)
round(x::ArbFloat{P}, ::RoundingMode{:FromZero}) where {P} = signbit(x) ? floor(x) : ceil(x)

round(x::ArbReal{P}, ::RoundingMode{:Up}) where {P} = ArbReal{P}(round(ArbFloat{P}(x), RoundingMode{:Up}))
round(x::ArbReal{P}, ::RoundingMode{:Down}) where {P} = ArbReal{P}(round(ArbFloat{P}(x), RoundingMode{:Down}))
round(x::ArbReal{P}, ::RoundingMode{:ToZero}) where {P} = ArbReal{P}(round(ArbFloat{P}(x), RoundingMode{:ToZero}))
round(x::ArbReal{P}, ::RoundingMode{:FromZero}) where {P} = ArbReal{P}(round(ArbFloat{P}(x), RoundingMode{:FromZero}))

function round(x::ArbFloat{P}, ::RoundingMode{:Nearest}) where {P}
    absx = abs(x)
    fl = floor(absx)
    cl = fl + 1
    xfl = absx - fl
    xcl = cl - absx
    if xfl < xcl
        copysign(fl, x)
    elseif xfl > xcl
        copysign(cl, x)
    elseif iseven(BigInt(fl))
        copysign(fl, x)
    else
        copysign(cl, x)
    end
end

round(x::ArbReal{P}, ::RoundingMode{:Nearest}) where {P} = ArbReal{P}(round(ArbFloat{P}(x), RoundNearest))

#=
function round(x::ArbComplex{P}, roundingmode::RoundingMode) where {P}
    z = ArbComplex{P}()
    rounding = match_rounding_mode(roundingmode)
    rounddir = ccall(@libarb(acb_set_round), Cint, (Ref{ArbComplex}, Ref{ArbComplex}, Clong, Cint), z, x, P, rounding)
    return z
end
=#

# int arf_set_round(arf_t res, const arf_t x, slong prec, arf_rnd_t rnd)
function round(x::ArbFloat{P}, bitprecision::Int, roundingmode::RoundingMode) where {P}
    z = ArbFloat{P}()
    rounding = match_rounding_mode(roundingmode)
    rounddir = ccall(@libarb(arf_set_round), Cint, (Ref{ArbFloat}, Ref{ArbFloat}, Clong, Cint), z, x, bitprecision, rounding)
    return z
end

function round(x::ArbFloat{P}, bitprecision::Int) where {P}
    z = ArbFloat{P}()
    rounding = match_rounding_mode(RoundNearest)
    rounddir = ccall(@libarb(arf_set_round), Cint, (Ref{ArbFloat}, Ref{ArbFloat}, Clong, Cint), z, x, bitprecision, rounding)
    return z
end

# void arb_set_round(arb_t y, const arb_t x, slong prec)
function round(x::ArbReal{P}, bitprecision::Int) where {P}
    z = ArbReal{P}()
    ccall(@libarb(arb_set_round), Cvoid, (Ref{ArbReal}, Ref{ArbReal}, Clong), z, x, bitprecision)
    return z
end

#void acb_set_round(acb_t z, const acb_t x, slong prec)
function round(x::ArbComplex{P}, bitprecision::Int) where {P}
    z = ArbComplex{P}()
    ccall(@libarb(acb_set_round), Cint, (Ref{ArbComplex}, Ref{ArbComplex}, Clong), z, x, bitprecision)
    return z
end

    
for A in (:ArbFloat, :ArbReal, :ArbComplex)
  @eval begin
    
    round(::Type{T}, x::$A{P}, rounding::RoundingMode=RoundNearest) where {P,T} =
       T(round(x, digits=P, base=rounding))

    function round(x::$A{P}, rounding::RoundingMode=RoundNearest; 
                   sigdigits::Integer = 0, digits::Integer = 0, base = 10) where {P}
        sigdigits = max(sigdigits, digits) 
        if base == 10
            round(x, digits=digits4bits(sigdigits), base=rounding) 
        elseif base ==  2
            round(x, digits=sigdigits, base=rounding)
        else
            throw(DomainError("base ($base) not supported"))
        end
     end
  end
                
end

#=
  round([T,] x, [r::RoundingMode])
  round(x, [r::RoundingMode]; digits::Integer=0, base = 10)
  round(x, [r::RoundingMode]; sigdigits::Integer, base = 10)

  Rounds the number x.

  Without keyword arguments, x is rounded to an integer value, returning a value of type T, or of the same type of x
  if no T is provided. An InexactError will be thrown if the value is not representable by T, similar to convert.

  If the digits keyword argument is provided, it rounds to the specified number of digits after the decimal place (or
  before if negative), in base base.

  If the sigdigits keyword argument is provided, it rounds to the specified number of significant digits, in base
  base.

  The RoundingMode r controls the direction of the rounding; the default is RoundNearest, which rounds to the nearest
  integer, with ties (fractional values of 0.5) being rounded to the nearest even integer. Note that round may give
  incorrect results if the global rounding mode is changed (see rounding).
=#


