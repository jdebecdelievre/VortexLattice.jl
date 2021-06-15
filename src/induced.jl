"""
    bound_induced_velocity(r1, r2, finite_core, core_size)

Compute the induced velocity (per unit circulation) for a bound vortex, at a
control point located at `r1` relative to the start of the bound vortex and `r2`
relative to the end of the bound vortex
"""
@inline function bound_induced_velocity(r1, r2, finite_core, core_size)

    if r1 == r2
        return zero(r1 .* r2)
    end

    nr1 = norm(r1)
    nr2 = norm(r2)

    if finite_core && !iszero(core_size)
        rdot = dot(r1, r2)
        r1s, r2s, εs = nr1^2, nr2^2, core_size^2
        f1 = cross(r1, r2)/(r1s*r2s - rdot^2 + εs*(r1s + r2s - 2*nr1*nr2))
        f2 = (r1s - rdot)/sqrt(r1s + εs) + (r2s - rdot)/sqrt(r2s + εs)
    else
        f1 = cross(r1, r2)/(nr1*nr2 + dot(r1, r2))
        f2 = (1/nr1 + 1/nr2)
    end

    Vhat = (f1*f2)/(4*pi)

    return Vhat
end

"""
    trailing_induced_velocity(r1, r2, xhat, finite_core, core_size)

Compute the induced velocity (per unit circulation) for a vortex trailing in
the `xhat` direction, at a control point located at `r` relative to the start of the
trailing vortex.
"""
@inline function trailing_induced_velocity(r, xhat, finite_core, core_size)

    nr = norm(r)

    rdot = dot(r, xhat)

    if finite_core
        εs = core_size^2
        tmp = εs/(nr + rdot)
        f = cross(r, xhat)/(nr*(nr - rdot + tmp))
    else
        f = cross(r, xhat)/(nr*(nr - rdot))
    end

    Vhat = -f/(4*pi)

    return Vhat
end

"""
    ring_induced_velocity(rcp, r11, r12, r21, r22; finite_core = false,
        core_size = 0.0, symmetric = false, xhat = [1,0,0], top = true, bottom = true,
        left = true, right = true, left_trailing = false, right_trailing = false,
        reflected_top = true, reflected_bottom = true, reflected_left = true,
        reflected_right = true, reflected_left_trailing = false, reflected_right_trailing = false)

Compute the induced velocity (per unit circulation) for a vortex ring defined by
the corners `r11`, `r12`, `r21`, and `r22` at a control point located at `rcp`

Also returns the induced velocity resulting from shared edges with panels
on the top, bottom, left, and right sides of the panel described by `r11`,
`r12`, `r21`, and `r22`.
"""
@inline function ring_induced_velocity(rcp, r11, r12, r21, r22;
    finite_core = false, core_size = 0.0, symmetric = false, xhat = SVector(1, 0, 0),
    top = true, bottom = true, left = true, right = true, left_trailing = false,
    right_trailing = false, reflected_top=true, reflected_bottom = true,
    reflected_left = true, reflected_right = true, reflected_left_trailing = false,
    reflected_right_trailing = false)

    # move origin to control point
    r1 = rcp - r11
    r2 = rcp - r12
    r3 = rcp - r22
    r4 = rcp - r21

    Vhat = zero(rcp) # current panel (from specified edges)
    Vhat_t = zero(rcp) # panel above this panel (from shared edges)
    Vhat_l = zero(rcp) # panel to the left of this panel (from shared edges)
    Vhat_r = zero(rcp) # panel to the right of this panel (from shared edges)
    Vhat_b = zero(rcp) # panel below this panel (from shared edges)

    # top edge
    if top
        vt = bound_induced_velocity(r1, r2, finite_core, core_size)
        # shared edge contribution from current panel
        Vhat += vt
        # shared edge contribution from panel above this panel
        Vhat_t -= vt
    end

    # right edge
    if right
        vr = bound_induced_velocity(r2, r3, finite_core, core_size)
        # shared edge contribution from current panel
        Vhat += vr
        # shared edge contribution from panel to the right of this panel
        Vhat_r -= vr
    end

    # right trailing vortex
    if right_trailing
        vrt = trailing_induced_velocity(r3, xhat, finite_core, core_size)
        # shared edge contribution from current panel
        Vhat += vrt
        # shared edge contribution from panel to the right of this panel
        Vhat_r -= vrt
    end

    # bottom edge
    if bottom
        vb = bound_induced_velocity(r3, r4, finite_core, core_size)
        # shared edge contribution from current panel
        Vhat += vb
        # shared edge contribution from panel below this panel
        Vhat_b -= vb
    end

    # left edge
    if left
        vl = bound_induced_velocity(r4, r1, finite_core, core_size)
        # shared edge contribution from current panel
        Vhat += vl
        # shared edge contribution from panel to the left of this panel
        Vhat_l -= vl
    end

    # left trailing vortex
    if left_trailing
        vlt = trailing_induced_velocity(r4, xhat, finite_core, core_size)
        # shared edge contribution from current panel
        Vhat -= vlt
        # shared edge contribution from panel to the left of this panel
        Vhat_l += vlt
    end

    if symmetric

        # move origin to control point
        r1 = rcp - flipy(r11)
        r2 = rcp - flipy(r12)
        r3 = rcp - flipy(r22)
        r4 = rcp - flipy(r21)

        # top edge
        if reflected_top
            vt = bound_induced_velocity(r2, r1, finite_core, core_size)
            # shared edge contribution from current panel
            Vhat += vt
            # shared edge contribution from panel above this panel
            Vhat_t -= vt
        end

        # right edge
        if reflected_right
            vr = bound_induced_velocity(r3, r2, finite_core, core_size)
            # shared edge contribution from current panel
            Vhat += vr
            # shared edge contribution from panel to the right of this panel
            Vhat_r -= vr
        end

        # right trailing vortex
        if reflected_right_trailing
            vrt = trailing_induced_velocity(r3, xhat, finite_core, core_size)
            # shared edge contribution from current panel
            Vhat -= vrt
            # shared edge contribution from panel to the right of this panel
            Vhat_r += vrt
        end

        # bottom edge
        if reflected_bottom
            vb = bound_induced_velocity(r4, r3, finite_core, core_size)
            # shared edge contribution from current panel
            Vhat += vb
            # shared edge contribution from panel below this panel
            Vhat_b -= vb
        end

        # left trailing vortex
        if reflected_left_trailing
            vlt = trailing_induced_velocity(r4, xhat, finite_core, core_size)
            # shared edge contribution from current panel
            Vhat += vlt
            # shared edge contribution from panel to the left of this panel
            Vhat_l -= vlt
        end

        # left edge
        if reflected_left
            vl = bound_induced_velocity(r1, r4, finite_core, core_size)
            # shared edge contribution from current panel
            Vhat += vl
            # shared edge contribution from panel to the left of this panel
            Vhat_l -= vl
        end
    end

    return Vhat, Vhat_t, Vhat_b, Vhat_l, Vhat_r
end

"""
    ring_induced_velocity(rcp, panel; kwargs...)

Compute the velocity (per unit circulation) induced by `panel` at a control point
located at `rcp`

Also returns the velocity induced by the shared edges of adjacent panels
on the top, bottom, left, and right sides of `panel`.
"""
@inline function ring_induced_velocity(rcp, panel; kwargs...)

    r11 = top_left(panel)
    r12 = top_right(panel)
    r21 = bottom_left(panel)
    r22 = bottom_right(panel)
    core_size = get_core_size(panel)

    return ring_induced_velocity(rcp, r11, r12, r21, r22; core_size=core_size, kwargs...)
end

"""
    induced_velocity(rcp, surface, Γ; kwargs...)

Compute the velocity induced by the grid of panels in `surface` at control point
`rcp`
"""
induced_velocity(rcp, surface::AbstractMatrix{<:SurfacePanel}, Γ; kwargs...)

"""
    induced_velocity_derivatives(rcp, surface, Γ, dΓ; kwargs...)

Compute the velocity induced by the grid of panels in `surface` at control point
`rcp` and its derivatives with respect to the freestream variables
"""
@inline function induced_velocity_derivatives(rcp,
    surface::AbstractMatrix{<:SurfacePanel}, Γ, dΓ; kwargs...)

    return induced_velocity(rcp, surface, Γ, dΓ; kwargs...)
end

"""
    induced_velocity(I::CartesianIndex, surface, Γ; kwargs...)

Compute the velocity induced by the grid of panels in `surface` on the top bound
vortex of panel `I` in `surface`.
"""
@inline function induced_velocity(I::CartesianIndex, surface::AbstractMatrix{<:SurfacePanel}, Γ;
    kwargs...)

    # extract the control point of interest
    rcp = top_center(surface[I])

    # set panel coordinates to skip
    skip_top = (I,)
    skip_bottom = (CartesianIndex(I[1]-1, I[2]),)

    return induced_velocity(rcp, surface, Γ; kwargs..., skip_top, skip_bottom)
end

"""
    induced_velocity_derivatives(I::CartesianIndex, surface, Γ, dΓ; kwargs...)

Compute the velocity induced by the grid of panels in `surface` on the top bound
vortex of panel `I` in `surface` and its derivatives with respect to the
freestream variables
"""
@inline function induced_velocity_derivatives(I::CartesianIndex,
    surface::AbstractMatrix{<:SurfacePanel}, Γ, dΓ; kwargs...)

    # extract the control point of interest
    rcp = top_center(surface[I])

    # set panel coordinates to skip
    skip_top = (I,)
    skip_bottom = (CartesianIndex(I[1]-1, I[2]),)

    return induced_velocity(rcp, surface, Γ, dΓ; kwargs..., skip_top, skip_bottom)
end

"""
    induced_velocity(is::Integer, surface, Γ; kwargs...)
Compute the velocity induced by the grid of panels in `surface` at the trailing
edge vertex corresponding to index `is`
"""
@inline function induced_velocity(is::Integer, surface::AbstractMatrix{<:SurfacePanel},
    Γ; nc = size(surface, 1), ns = size(surface, 2), wake_shedding_locations = nothing,
    kwargs...)

    # extract the control point of interest
    if is <= ns
        rcp = bottom_left(surface[nc, is])
    else
        rcp = bottom_right(surface[nc, is-1])
    end

    # set panel coordinates to skip
    skip_top = (CartesianIndex(nc+1, is-1), CartesianIndex(nc+1, is))
    skip_bottom = (CartesianIndex(nc, is-1), CartesianIndex(nc, is))
    skip_left = (CartesianIndex(nc, is), CartesianIndex(nc+1, is))
    skip_right = (CartesianIndex(nc, is-1), CartesianIndex(nc+1, is-1))
    skip_left_trailing = (CartesianIndex(nc, is),)
    skip_right_trailing = (CartesianIndex(nc, is-1),)

    return induced_velocity(rcp, surface, Γ; kwargs..., nc, ns, skip_bottom,
        skip_left, skip_right, skip_left_trailing, skip_right_trailing)
end

"""
    induced_velocity(rcp, wake::AbstractMatrix{<:WakePanel}; kwargs...)

Compute the velocity induced by the grid of wake panels in `wake` at
control point `rcp`
"""
induced_velocity(rcp, wake::AbstractMatrix{<:WakePanel}; kwargs...)

"""
    induced_velocity(I::CartesianIndex, wake; kwargs...)

Compute the induced velocity from the grid of wake panels in `wake` at the
vertex corresponding to index `I`
"""
@inline function induced_velocity(I::CartesianIndex, wake::AbstractMatrix{<:WakePanel};
    nc = size(wake, 1), ns = size(wake, 2), kwargs...)

    if iszero(nc)
        return @SVector zeros(eltype(eltype(wake)), 3)
    end

    # extract the control point of interest
    if I[1] <= nc && I[2] <= ns
        rcp = top_left(wake[I[1], I[2]])
    elseif I[1] <= nc && I[2] == ns + 1
        rcp = top_right(wake[I[1], I[2]-1])
    elseif I[1] == nc + 1 && I[2] <= ns
        rcp = bottom_left(wake[I[1]-1, I[2]])
    else # I[1] == nc + 1 && I[2] == ns + 1
        rcp = bottom_right(wake[I[1]-1, I[2]-1])
    end

    # set panel coordinates to skip
    skip_top = (I, CartesianIndex(I[1], I[2]-1))
    skip_bottom = (CartesianIndex(I[1]-1, I[2]), CartesianIndex(I[1]-1, I[2]-1))
    skip_left = (I, CartesianIndex(I[1]-1, I[2]))
    skip_right = (CartesianIndex(I[1], I[2]-1), CartesianIndex(I[1]-1, I[2]-1))
    skip_left_trailing = (CartesianIndex(I[1]-1, I[2]),)
    skip_right_trailing = (CartesianIndex(I[1]-1, I[2]-1),)

    return induced_velocity(rcp, wake; kwargs..., nc, ns,
        skip_top, skip_bottom, skip_left, skip_right,
        skip_left_trailing, skip_right_trailing)
end

"""
    induced_velocity(rcp, surface, Γ = nothing, dΓ = nothing; kwargs...)

Compute the induced velocity from the grid of panels in `surface` at `rcp` using
the circulation strengths provided in Γ.

# Keyword Arguments
 - `nc`: Number of panels in the chordwise direction. Defaults to `size(surface, 1)`
 - `ns`: Number of panels in the spanwise direction. Defaults to `size(surface, 2)`
 - `finite_core`: Flag indicating whether the finite core model should be used
 - `symmetric`: Flag indicating whether sending panels should be mirrored across the X-Z plane
 - `wake_shedding_locations`: Wake shedding locations for the trailing edge panels in `surface`
 - `trailing_vortices`: Indicates whether trailing vortices are used. Defaults to `true`.
 - `xhat`: Direction in which trailing vortices are shed if `trailing_vortices = true`.
    Defaults to [1, 0, 0]
 - `skip_leading_edge = false`: Indicates whether to skip the leading edge.  This flag
    may be used to skip calculating the leading bound vortex of a wake when its
    influence cancels exactly with the trailing bound vortex of a surface.
 - `skip_inside_edges = false`: Indicates whether to skip all horizontal bound
    vortices except those located at the leading and trailing edges.
    This flag may be used to skip calculating a wake's (internal) horizontal
    bound vortices during steady state simulations since the influence of adjacent
    wake panels in a chordwise strip cancels exactly in steady state simulations.
 - `skip_trailing_edge = false`: Indicates whether to skip the trailing edge.
    The trailing edge is always skipped if `trailing_vortices = true`
 - `skip_top`: Tuple containing panel indices whose top bound vortex is coincident with
    `rcp` and should therefore be skipped.
 - `skip_bottom`: Tuple containing panel indices whose bottom bound vortex is coincident with
    `rcp` and should therefore be skipped.
 - `skip_left`: Tuple containing panel indices whose left bound vortex is coincident with
    `rcp` and should therefore be skipped.
 - `skip_right`: Tuple containing panel indices whose right bound vortex is coincident with
    `rcp` and should therefore be skipped.
 - `skip_left_trailing`: Tuple containing panel indices whose left trailing vortex
    is coincident with `rcp` and should therefore be skipped.
 - `skip_right_trailing`: Tuple containing panel indices whose right trailing vortex
    is coincident with `rcp` and should therefore be skipped.
"""
@inline function induced_velocity(rcp, surface, Γ = nothing, dΓ = nothing;
    nc = size(surface, 1), ns = size(surface, 2),
    symmetric = false, finite_core = true,
    wake_shedding_locations = nothing,
    trailing_vortices = true, xhat = SVector(1, 0, 0),
    skip_leading_edge = false, skip_inside_edges = false, skip_trailing_edge = false,
    skip_top = (), skip_bottom = (),
    skip_left = (), skip_right = (),
    skip_left_trailing = (), skip_right_trailing = ())

    # check if we are working with derivatives
    derivatives = !isnothing(dΓ)

    # unpack derivatives
    if derivatives
        Γ_a, Γ_b, Γ_p, Γ_q, Γ_r = dΓ
    end

    # linear index for accessing Γ and dΓ
    ls = LinearIndices((nc, ns))

    # initialize output(s)
    Vind = zero(rcp)

    if derivatives
        Vind_a = zero(rcp)
        Vind_b = zero(rcp)
        Vind_p = zero(rcp)
        Vind_q = zero(rcp)
        Vind_r = zero(rcp)
    end

    # if no panels, no influence
    if iszero(nc)
        if derivatives
            # pack up derivatives
            dVind = Vind_a, Vind_b, Vind_p, Vind_q, Vind_r
            # return early
            return Vind, dVind
        else
            # return early
            return Vind
        end
    end

    # we can reuse edges if the finite core model is disabled
    reuse_edges = !finite_core

    # when skipping vortices, keep their reflections unless `rcp` lies on the symmetry plane
    keep_reflected = not_on_symmetry_plane(rcp)

    if reuse_edges
        # use more efficient loop when we can reuse edges

        # calculate influence of all panels except right and trailing edges
        for j2 in 1:ns-1, j1 in 1:nc-1

            # current panel index
            J = CartesianIndex(j1, j2)

            # check if top bound vortex should be included
            include_top =
                !(J in skip_top) && # skipped indices
                !(j1 == 1 && skip_leading_edge) && # skipped leading edge
                !(j1 != 1 && skip_inside_edges) # skipped inside edges

            # check if reflection of top bound vortex should be included
            include_reflected_top =
                (!(J in skip_top) || keep_reflected) && # skipped indices
                !(j1 == 1 && skip_leading_edge) && # skipped leading edge
                !(j1 != 1 && skip_inside_edges) # skipped inside edges

            # check if left bound vortex should be included
            include_left = !(J in skip_left)

            # check if reflection of left bound vortex should be included
            include_reflected_left = (!(J in skip_left) || keep_reflected)

            # skip bottom and right edges since their influence is added during
            # another panel's induced velocity calculations
            include_bottom = false
            include_reflected_bottom = false
            include_right = false
            include_reflected_right = false

            # compute induced velocity
            Vhat, Vhat_t, Vhat_b, Vhat_l, Vhat_r = ring_induced_velocity(rcp, surface[j1, j2];
                symmetric = symmetric,
                finite_core = finite_core,
                xhat = xhat,
                top = include_top,
                reflected_top = include_reflected_top,
                left = include_left,
                reflected_left = include_reflected_left,
                bottom = include_bottom,
                reflected_bottom = include_reflected_bottom,
                right = include_right,
                reflected_right = include_reflected_right)

            # add partial contribution from current panel
            if isnothing(Γ)
                Vind += Vhat * surface[j1, j2].gamma
            else
                j = ls[j1, j2]

                Vind += Vhat * Γ[j]

                if derivatives
                    Vind_a += Vhat*Γ_a[j]
                    Vind_b += Vhat*Γ_b[j]
                    Vind_p += Vhat*Γ_p[j]
                    Vind_q += Vhat*Γ_q[j]
                    Vind_r += Vhat*Γ_r[j]
                end
            end

            # add partial contribution from  the bottom edge of the panel above this one (if applicable)
            if j1 > 1
                if isnothing(Γ)
                    Vind += Vhat_t * surface[j1-1, j2].gamma
                else
                    j = ls[j1-1, j2]

                    Vind += Vhat_t * Γ[j]

                    if derivatives
                        Vind_a += Vhat_t*Γ_a[j]
                        Vind_b += Vhat_t*Γ_b[j]
                        Vind_p += Vhat_t*Γ_p[j]
                        Vind_q += Vhat_t*Γ_q[j]
                        Vind_r += Vhat_t*Γ_r[j]
                    end
                end
            end

            # add partial contribution from the right edge of the panel to the left of this one (if applicable)
            if j2 > 1
                if isnothing(Γ)
                    Vind += Vhat_l * surface[j1, j2-1].gamma
                else
                    j = ls[j1, j2-1]

                    Vind += Vhat_l * Γ[j]

                    if derivatives
                        Vind_a += Vhat_l*Γ_a[j]
                        Vind_b += Vhat_l*Γ_b[j]
                        Vind_p += Vhat_l*Γ_p[j]
                        Vind_q += Vhat_l*Γ_q[j]
                        Vind_r += Vhat_l*Γ_r[j]
                    end
                end
            end
        end

        # panels on the right edge (excluding the bottom right corner)
        j2 = ns
        for j1 in 1:nc-1

            # current panel index
            J = CartesianIndex(j1, j2)

            # check if top bound vortex should be included
            include_top =
                !(J in skip_top) && # skipped indices
                !(j1 == 1 && skip_leading_edge) && # skipped leading edge
                !(j1 != 1 && skip_inside_edges) # skipped inside edges

            # check if reflection of top bound vortex should be included
            include_reflected_top =
                (!(J in skip_top) || keep_reflected) && # skipped indices
                !(j1 == 1 && skip_leading_edge) && # skipped leading edge
                !(j1 != 1 && skip_inside_edges) # skipped inside edges

            # check if left bound vortex should be included
            include_left = !(J in skip_left)

            # check if reflection of left bound vortex should be included
            include_reflected_left = (!(J in skip_left) || keep_reflected)

            # check if right bound vortex should be included
            include_right = !(J in skip_right)

            # check if reflection of right bound vortex should be included
            include_reflected_right = (!(J in skip_right) || keep_reflected)

            # skip bottom edge since its influence is added during another
            # panel's induced velocity calculations
            include_bottom = false
            include_reflected_bottom = false

            # compute induced velocity
            Vhat, Vhat_t, Vhat_b, Vhat_l, Vhat_r = ring_induced_velocity(rcp, surface[j1, j2];
                symmetric = symmetric,
                finite_core = finite_core,
                xhat = xhat,
                top = include_top,
                reflected_top = include_reflected_top,
                left = include_left,
                reflected_left = include_reflected_left,
                bottom = include_bottom,
                reflected_bottom = include_reflected_bottom,
                right = include_right,
                reflected_right = include_reflected_right)

            # add partial contribution from current panel
            if isnothing(Γ)
                Vind += Vhat * surface[j1, j2].gamma
            else
                j = ls[j1, j2]

                Vind += Vhat * Γ[j]

                if derivatives
                    Vind_a += Vhat*Γ_a[j]
                    Vind_b += Vhat*Γ_b[j]
                    Vind_p += Vhat*Γ_p[j]
                    Vind_q += Vhat*Γ_q[j]
                    Vind_r += Vhat*Γ_r[j]
                end
            end

            # add partial contribution from  the bottom edge of the panel above this one (if applicable)
            if j1 > 1
                if isnothing(Γ)
                    Vind += Vhat_t * surface[j1-1, j2].gamma
                else
                    j = ls[j1-1, j2]

                    Vind += Vhat_t * Γ[j]

                    if derivatives
                        Vind_a += Vhat_t*Γ_a[j]
                        Vind_b += Vhat_t*Γ_b[j]
                        Vind_p += Vhat_t*Γ_p[j]
                        Vind_q += Vhat_t*Γ_q[j]
                        Vind_r += Vhat_t*Γ_r[j]
                    end
                end
            end

            # add partial contribution from the right edge of the panel to the left of this one (if applicable)
            if j2 > 1
                if isnothing(Γ)
                    Vind += Vhat_l * surface[j1, j2-1].gamma
                else
                    j = ls[j1, j2-1]

                    Vind += Vhat_l * Γ[j]

                    if derivatives
                        Vind_a += Vhat_l*Γ_a[j]
                        Vind_b += Vhat_l*Γ_b[j]
                        Vind_p += Vhat_l*Γ_p[j]
                        Vind_q += Vhat_l*Γ_q[j]
                        Vind_r += Vhat_l*Γ_r[j]
                    end
                end
            end
        end

        # panels on the trailing edge (excluding the bottom right corner)
        j1 = nc
        for j2 in 1:ns-1

            # current panel index
            J = CartesianIndex(j1, j2)

            # check if top bound vortex should be included
            include_top =
                !(J in skip_top) && # skipped indices
                !(j1 == 1 && skip_leading_edge) && # skipped leading edge
                !(j1 != 1 && skip_inside_edges) # skipped inside edges

            # check if reflection of top bound vortex should be included
            include_reflected_top =
                (!(J in skip_top) || keep_reflected) && # skipped indices
                !(j1 == 1 && skip_leading_edge) && # skipped leading edge
                !(j1 != 1 && skip_inside_edges) # skipped inside edges

            # check if the bottom bound vortex should be included
            include_bottom =
                isnothing(wake_shedding_locations) &&
                !(J in skip_bottom) && # skipped indices
                !trailing_vortices && # no trailing horseshoe vortex
                !skip_trailing_edge # skipped trailing edge

            # check if the reflection of the bottom bound vortex should be included
            include_reflected_bottom =
                isnothing(wake_shedding_locations) &&
                (!(J in skip_bottom) || keep_reflected) && # skipped indices
                !trailing_vortices && # no trailing horseshoe vortex
                !skip_trailing_edge # skipped trailing edge

            # check if left bound vortex should be included
            include_left = !(J in skip_left)

            # check if reflection of left bound vortex should be included
            include_reflected_left = (!(J in skip_left) || keep_reflected)

            # check if left trailing vortex should be included
            include_left_trailing =
                isnothing(wake_shedding_locations) &&
                !(J in skip_left_trailing) && # skipped indices
                trailing_vortices # trailing horseshoe vortex

            # check if reflection of left trailing vortex should be included
            include_reflected_left_trailing =
                isnothing(wake_shedding_locations) &&
                (!(J in skip_left_trailing) || keep_reflected) && # skipped indices
                trailing_vortices # trailing horseshoe vortex

            # skip right edge and right trailing vortex since their influence is
            # added during another panel's induced velocity calculations
            include_right = false
            include_reflected_right = false
            include_right_trailing = false
            include_reflected_right_trailing = false

            # compute induced velocity
            Vhat, Vhat_t, Vhat_b, Vhat_l, Vhat_r = ring_induced_velocity(rcp, surface[j1, j2];
                symmetric = symmetric,
                finite_core = finite_core,
                xhat = xhat,
                top = include_top,
                reflected_top = include_reflected_top,
                bottom = include_bottom,
                reflected_bottom = include_reflected_bottom,
                left = include_left,
                reflected_left = include_reflected_left,
                right = include_right,
                reflected_right = include_reflected_right,
                left_trailing = include_left_trailing,
                reflected_left_trailing = include_reflected_left_trailing,
                right_trailing = include_right_trailing,
                reflected_right_trailing = include_reflected_right_trailing)

            # add partial contribution from current panel
            if isnothing(Γ)
                Vind += Vhat * surface[j1, j2].gamma
            else
                j = ls[j1, j2]

                Vind += Vhat * Γ[j]

                if derivatives
                    Vind_a += Vhat*Γ_a[j]
                    Vind_b += Vhat*Γ_b[j]
                    Vind_p += Vhat*Γ_p[j]
                    Vind_q += Vhat*Γ_q[j]
                    Vind_r += Vhat*Γ_r[j]
                end
            end

            # add partial contribution from the bottom edge of the panel above this one (if applicable)
            if j1 > 1
                if isnothing(Γ)
                    Vind += Vhat_t * surface[j1-1, j2].gamma
                else
                    j = ls[j1-1, j2]

                    Vind += Vhat_t * Γ[j]

                    if derivatives
                        Vind_a += Vhat_t*Γ_a[j]
                        Vind_b += Vhat_t*Γ_b[j]
                        Vind_p += Vhat_t*Γ_p[j]
                        Vind_q += Vhat_t*Γ_q[j]
                        Vind_r += Vhat_t*Γ_r[j]
                    end
                end
            end

            # add partial contribution from the right edge of the panel to the left of this one (if applicable)
            if j2 > 1
                if isnothing(Γ)
                    Vind += Vhat_l * surface[j1, j2-1].gamma
                else
                    j = ls[j1, j2-1]

                    Vind += Vhat_l * Γ[j]

                    if derivatives
                        Vind_a += Vhat_l*Γ_a[j]
                        Vind_b += Vhat_l*Γ_b[j]
                        Vind_p += Vhat_l*Γ_p[j]
                        Vind_q += Vhat_l*Γ_q[j]
                        Vind_r += Vhat_l*Γ_r[j]
                    end
                end
            end

            # add influence of surface-wake interface panel
            if !isnothing(wake_shedding_locations)

                J = CartesianIndex(j1+1, j2)

                panel = surface[j1, j2]
                r11 = bottom_left(panel)
                r12 = bottom_right(panel)
                r21 = wake_shedding_locations[j2]
                r22 = wake_shedding_locations[j2+1]
                core_size = get_core_size(panel)

                Jte = CartesianIndex(j1, j2)
                zleft = r11 == r21
                zright = r12 == r22

                # check if the bottom bound vortex should be included
                include_bottom =
                    !(Jte in skip_bottom && zleft && zright) &&
                    !(J in skip_bottom) && # skipped indices
                    !trailing_vortices && # no trailing horseshoe vortex
                    !skip_trailing_edge # skipped trailing edge

                # check if the reflection of the bottom bound vortex should be included
                include_reflected_bottom =
                    (!(Jte in skip_bottom && zleft && zright) || keep_reflected) &&
                    (!(J in skip_bottom) || keep_reflected) && # skipped indices
                    !trailing_vortices && # no trailing horseshoe vortex
                    !skip_trailing_edge # skipped trailing edge

                # check if left bound vortex should be included
                include_left = !(J in skip_left) && !zleft

                # check if reflection of left bound vortex should be included
                include_reflected_left = (!(J in skip_left) || keep_reflected) && !zleft

                # check if left trailing vortex should be included
                include_left_trailing =
                    !(Jte in skip_left_trailing && zleft) &&
                    !(J in skip_left_trailing) && # skipped indices
                    trailing_vortices # trailing horseshoe vortex

                # check if reflection of left trailing vortex should be included
                include_reflected_left_trailing =
                    (!(Jte in skip_left_trailing && zleft) || keep_reflected) &&
                    (!(J in skip_left_trailing) || keep_reflected) && # skipped indices
                    trailing_vortices # trailing horseshoe vortex

                # skip top edge because the bottom edge of the trailing edge
                # panel cancels its influence exactly.
                include_top = false
                include_reflected_top = false

                # skip right edge and right trailing vortex since their influence is
                # added during another panel's induced velocity calculations
                include_right = false
                include_reflected_right = false
                include_right_trailing = false
                include_reflected_right_trailing = false

                Vhat, Vhat_t, Vhat_b, Vhat_l, Vhat_r = ring_induced_velocity(rcp,
                    r11, r12, r21, r22,
                    finite_core = finite_core,
                    core_size = core_size,
                    symmetric = symmetric,
                    xhat = xhat,
                    top = include_top,
                    reflected_top = include_reflected_top,
                    bottom = include_bottom,
                    reflected_bottom = include_reflected_bottom,
                    left = include_left,
                    reflected_left = include_reflected_left,
                    right = include_right,
                    reflected_right = include_reflected_right,
                    left_trailing = include_left_trailing,
                    reflected_left_trailing = include_reflected_left_trailing,
                    right_trailing = include_right_trailing,
                    reflected_right_trailing = include_reflected_right_trailing)

                # add contribution from interface panel
                if isnothing(Γ)
                    Vind += Vhat * surface[j1, j2].gamma
                else
                    j = ls[j1, j2]

                    Vind += Vhat * Γ[j]

                    if derivatives
                        Vind_a += Vhat*Γ_a[j]
                        Vind_b += Vhat*Γ_b[j]
                        Vind_p += Vhat*Γ_p[j]
                        Vind_q += Vhat*Γ_q[j]
                        Vind_r += Vhat*Γ_r[j]
                    end
                end

                # add partial contribution from the right edge of the panel to the left of this one (if applicable)
                if j2 > 1
                    if isnothing(Γ)
                        Vind += Vhat_l * surface[j1, j2-1].gamma
                    else
                        j = ls[j1, j2-1]

                        Vind += Vhat_l * Γ[j]

                        if derivatives
                            Vind_a += Vhat_l*Γ_a[j]
                            Vind_b += Vhat_l*Γ_b[j]
                            Vind_p += Vhat_l*Γ_p[j]
                            Vind_q += Vhat_l*Γ_q[j]
                            Vind_r += Vhat_l*Γ_r[j]
                        end
                    end
                end
            end
        end

        # bottom right corner
        j1 = nc
        j2 = ns

        # current panel index
        J = CartesianIndex(j1, j2)

        # check if top bound vortex should be included
        include_top =
            !(J in skip_top) && # skipped indices
            !(j1 == 1 && skip_leading_edge) && # skipped leading edge
            !(j1 != 1 && skip_inside_edges) # skipped inside edges

        # check if reflection of top bound vortex should be included
        include_reflected_top =
            (!(J in skip_top) || keep_reflected) && # skipped indices
            !(j1 == 1 && skip_leading_edge) && # skipped leading edge
            !(j1 != 1 && skip_inside_edges) # skipped inside edges

        # check if the bottom bound vortex should be included
        include_bottom =
            isnothing(wake_shedding_locations) &&
            !(J in skip_bottom) && # skipped indices
            !trailing_vortices && # no trailing horseshoe vortex
            !skip_trailing_edge # skipped trailing edge

        # check if the reflection of the bottom bound vortex should be included
        include_reflected_bottom =
            isnothing(wake_shedding_locations) &&
            (!(J in skip_bottom) || keep_reflected) && # skipped indices
            !trailing_vortices && # no trailing horseshoe vortex
            !skip_trailing_edge # skipped trailing edge

        # check if left bound vortex should be included
        include_left = !(J in skip_left)

        # check if reflection of left bound vortex should be included
        include_reflected_left = (!(J in skip_left) || keep_reflected)

        # check if right bound vortex should be included
        include_right = !(J in skip_right)

        # check if reflection of right bound vortex should be included
        include_reflected_right = (!(J in skip_right) || keep_reflected)

        # check if left trailing vortex should be included
        include_left_trailing =
            isnothing(wake_shedding_locations) &&
            !(J in skip_left_trailing) && # skipped indices
            trailing_vortices # trailing horseshoe vortex

        # check if reflection of left trailing vortex should be included
        include_reflected_left_trailing =
            isnothing(wake_shedding_locations) &&
            (!(J in skip_left_trailing) || keep_reflected) && # skipped indices
            trailing_vortices # trailing horseshoe vortex

        # check if left trailing vortex should be included
        include_right_trailing =
            isnothing(wake_shedding_locations) &&
            !(J in skip_right_trailing) && # skipped indices
            trailing_vortices # trailing horseshoe vortex

        # check if reflection of right trailing vortex should be included
        include_reflected_right_trailing =
            isnothing(wake_shedding_locations) &&
            (!(J in skip_right_trailing) || keep_reflected) && # skipped indices
            trailing_vortices # trailing horseshoe vortex

        # compute induced velocity
        Vhat, Vhat_t, Vhat_b, Vhat_l, Vhat_r = ring_induced_velocity(rcp, surface[j1, j2];
            finite_core = finite_core,
            symmetric = symmetric,
            xhat = xhat,
            top = include_top,
            reflected_top = include_reflected_top,
            bottom = include_bottom,
            reflected_bottom = include_reflected_bottom,
            left = include_left,
            reflected_left = include_reflected_left,
            right = include_right,
            reflected_right = include_reflected_right,
            left_trailing = include_left_trailing,
            reflected_left_trailing = include_reflected_left_trailing,
            right_trailing = include_right_trailing,
            reflected_right_trailing = include_reflected_right_trailing)

        # add partial contribution from current panel
        if isnothing(Γ)
            Vind += Vhat * surface[j1, j2].gamma
        else
            j = ls[j1, j2]

            Vind += Vhat * Γ[j]

            if derivatives
                Vind_a += Vhat*Γ_a[j]
                Vind_b += Vhat*Γ_b[j]
                Vind_p += Vhat*Γ_p[j]
                Vind_q += Vhat*Γ_q[j]
                Vind_r += Vhat*Γ_r[j]
            end
        end

        # add partial contribution from  the bottom edge of the panel above this one (if applicable)
        if j1 > 1
            if isnothing(Γ)
                Vind += Vhat_t * surface[j1-1, j2].gamma
            else
                j = ls[j1-1, j2]

                Vind += Vhat_t * Γ[j]

                if derivatives
                    Vind_a += Vhat_t*Γ_a[j]
                    Vind_b += Vhat_t*Γ_b[j]
                    Vind_p += Vhat_t*Γ_p[j]
                    Vind_q += Vhat_t*Γ_q[j]
                    Vind_r += Vhat_t*Γ_r[j]
                end
            end
        end

        # add partial contribution from the right edge of the panel to the left of this one (if applicable)
        if j2 > 1
            if isnothing(Γ)
                Vind += Vhat_l * surface[j1, j2-1].gamma
            else
                j = ls[j1, j2-1]

                Vind += Vhat_l * Γ[j]

                if derivatives
                    Vind_a += Vhat_l*Γ_a[j]
                    Vind_b += Vhat_l*Γ_b[j]
                    Vind_p += Vhat_l*Γ_p[j]
                    Vind_q += Vhat_l*Γ_q[j]
                    Vind_r += Vhat_l*Γ_r[j]
                end
            end
        end

        # add influence of surface-wake interface panel
        if !isnothing(wake_shedding_locations)

            J = CartesianIndex(j1+1, j2)

            panel = surface[j1, j2]
            r11 = bottom_left(panel)
            r12 = bottom_right(panel)
            r21 = wake_shedding_locations[j2]
            r22 = wake_shedding_locations[j2+1]
            core_size = get_core_size(panel)

            Jte = CartesianIndex(j1, j2)
            zleft = r11 == r21
            zright = r12 == r22

            # check if the bottom bound vortex should be included
            include_bottom =
                !(Jte in skip_bottom && zleft && zright) &&
                !(J in skip_bottom) && # skipped indices
                !trailing_vortices && # no trailing horseshoe vortex
                !skip_trailing_edge # skipped trailing edge

            # check if the reflection of the bottom bound vortex should be included
            include_reflected_bottom =
                (!(Jte in skip_bottom && zleft && zright) || keep_reflected) &&
                (!(J in skip_bottom) || keep_reflected) && # skipped indices
                !trailing_vortices && # no trailing horseshoe vortex
                !skip_trailing_edge # skipped trailing edge

            # check if left bound vortex should be included
            include_left = !(J in skip_left) && !zleft

            # check if reflection of left bound vortex should be included
            include_reflected_left = (!(J in skip_left) || keep_reflected) && !zleft

            # check if right bound vortex should be included
            include_right = !(J in skip_right) && !zright

            # check if reflection of right bound vortex should be included
            include_reflected_right = (!(J in skip_right) || keep_reflected) && !zright

            # check if left trailing vortex should be included
            include_left_trailing =
                !(Jte in skip_left_trailing && zleft) &&
                !(J in skip_left_trailing) && # skipped indices
                trailing_vortices # trailing horseshoe vortex

            # check if reflection of left trailing vortex should be included
            include_reflected_left_trailing =
                (!(Jte in skip_left_trailing && zleft) || keep_reflected) &&
                (!(J in skip_left_trailing) || keep_reflected) && # skipped indices
                trailing_vortices # trailing horseshoe vortex

            # check if left trailing vortex should be included
            include_right_trailing =
                !(Jte in skip_right_trailing && zright) &&
                !(J in skip_right_trailing) && # skipped indices
                trailing_vortices # trailing horseshoe vortex

            # check if reflection of right trailing vortex should be included
            include_reflected_right_trailing =
                (!(Jte in skip_right_trailing && zright) || keep_reflected) &&
                (!(J in skip_right_trailing) || keep_reflected) && # skipped indices
                trailing_vortices # trailing horseshoe vortex

            # skip top edge because the bottom edge of the trailing edge
            # panel cancels its influence exactly.
            include_top = false
            include_reflected_top = false

            Vhat, Vhat_t, Vhat_b, Vhat_l, Vhat_r = ring_induced_velocity(rcp,
                r11, r12, r21, r22,
                finite_core = finite_core,
                core_size = core_size,
                symmetric = symmetric,
                xhat = xhat,
                top = include_top,
                reflected_top = include_reflected_top,
                bottom = include_bottom,
                reflected_bottom = include_reflected_bottom,
                left = include_left,
                reflected_left = include_reflected_left,
                right = include_right,
                reflected_right = include_reflected_right,
                left_trailing = include_left_trailing,
                reflected_left_trailing = include_reflected_left_trailing,
                right_trailing = include_right_trailing,
                reflected_right_trailing = include_reflected_right_trailing)

            # add contribution from interface panel
            if isnothing(Γ)
                Vind += Vhat * surface[j1, j2].gamma
            else
                j = ls[j1, j2]

                Vind += Vhat * Γ[j]

                if derivatives
                    Vind_a += Vhat*Γ_a[j]
                    Vind_b += Vhat*Γ_b[j]
                    Vind_p += Vhat*Γ_p[j]
                    Vind_q += Vhat*Γ_q[j]
                    Vind_r += Vhat*Γ_r[j]
                end
            end

            # add partial contribution from the right edge of the panel to the left of this one (if applicable)
            if j2 > 1
                if isnothing(Γ)
                    Vind += Vhat_l * surface[j1, j2-1].gamma
                else
                    j = ls[j1, j2-1]

                    Vind += Vhat_l * Γ[j]

                    if derivatives
                        Vind_a += Vhat_l*Γ_a[j]
                        Vind_b += Vhat_l*Γ_b[j]
                        Vind_p += Vhat_l*Γ_p[j]
                        Vind_q += Vhat_l*Γ_q[j]
                        Vind_r += Vhat_l*Γ_r[j]
                    end
                end
            end
        end

    else

        # calculate influence of all panels except trailing edge panels
        for j2 in 1:ns, j1 in 1:nc-1

            J = CartesianIndex(j1, j2)

            # check if top bound vortex should be included
            include_top =
                !(J in skip_top) && # skipped indices
                !(j1 == 1 && skip_leading_edge) && # skipped leading edge
                !(j1 != 1 && skip_inside_edges) # skipped inside edges

            # check if reflection of top bound vortex should be included
            include_reflected_top =
                (!(J in skip_top) || keep_reflected) && # skipped indices
                !(j1 == 1 && skip_leading_edge) && # skipped leading edge
                !(j1 != 1 && skip_inside_edges) # skipped inside edges

            # check if the bottom bound vortex should be included
            include_bottom =
                !(J in skip_bottom) && # skipped indices
                !(J in skip_inside_edges) # skipped inside edges

            # check if the reflection of the bottom bound vortex should be included
            include_reflected_bottom =
                (!(J in skip_bottom) || keep_reflected) && # skipped indices
                !(J in skip_inside_edges) # skipped inside edges

            # check if left bound vortex should be included
            include_left = !(J in skip_left)

            # check if reflection of left bound vortex should be included
            include_reflected_left = (!(J in skip_left) || keep_reflected)

            # check if right bound vortex should be included
            include_right = !(J in skip_right)

            # check if reflection of right bound vortex should be included
            include_reflected_right = (!(J in skip_right) || keep_reflected)

            # compute induced velocity
            Vhat, Vhat_t, Vhat_b, Vhat_l, Vhat_r = ring_induced_velocity(rcp, surface[j1, j2];
                finite_core = finite_core,
                symmetric = symmetric,
                xhat = xhat,
                top = include_top,
                reflected_top = include_reflected_top,
                bottom = include_bottom,
                reflected_bottom = include_reflected_bottom,
                left = include_left,
                reflected_left = include_reflected_left,
                right = include_right,
                reflected_right = include_reflected_right)

            # add contribution from current panel
            if isnothing(Γ)
                Vind += Vhat * surface[j1, j2].gamma
            else
                j = ls[j1, j2]

                Vind += Vhat * Γ[j]

                if derivatives
                    Vind_a += Vhat*Γ_a[j]
                    Vind_b += Vhat*Γ_b[j]
                    Vind_p += Vhat*Γ_p[j]
                    Vind_q += Vhat*Γ_q[j]
                    Vind_r += Vhat*Γ_r[j]
                end
            end
        end

        # calculate influence of all trailing edge panels
        j1 = nc
        for j2 in 1:ns

            J = CartesianIndex(j1, j2)

            # check if top bound vortex should be included
            include_top =
                !(J in skip_top) && # skipped indices
                !(j1 == 1 && skip_leading_edge) && # skipped leading edge
                !(j1 != 1 && skip_inside_edges) # skipped inside edges

            # check if reflection of top bound vortex should be included
            include_reflected_top =
                (!(J in skip_top) || keep_reflected) && # skipped indices
                !(j1 == 1 && skip_leading_edge) && # skipped leading edge
                !(j1 != 1 && skip_inside_edges) # skipped inside edges

            # check if the bottom bound vortex should be included
            include_bottom =
                isnothing(wake_shedding_locations) &&
                !(J in skip_bottom) && # skipped indices
                !trailing_vortices && # no trailing horseshoe vortex
                !skip_trailing_edge # skipped trailing edge

            # check if the reflection of the bottom bound vortex should be included
            include_reflected_bottom =
                isnothing(wake_shedding_locations) &&
                (!(J in skip_bottom) || keep_reflected) && # skipped indices
                !trailing_vortices && # no trailing horseshoe vortex
                !skip_trailing_edge # skipped trailing edge

            # check if left bound vortex should be included
            include_left = !(J in skip_left)

            # check if reflection of left bound vortex should be included
            include_reflected_left = (!(J in skip_left) || keep_reflected)

            # check if right bound vortex should be included
            include_right = !(J in skip_right)

            # check if reflection of right bound vortex should be included
            include_reflected_right = (!(J in skip_right) || keep_reflected)

            # check if left trailing vortex should be included
            include_left_trailing =
                isnothing(wake_shedding_locations) &&
                !(J in skip_left_trailing) && # skipped indices
                trailing_vortices # trailing horseshoe vortex

            # check if reflection of left trailing vortex should be included
            include_reflected_left_trailing =
                isnothing(wake_shedding_locations) &&
                (!(J in skip_left_trailing) || keep_reflected) && # skipped indices
                trailing_vortices # trailing horseshoe vortex

            # check if left trailing vortex should be included
            include_right_trailing =
                isnothing(wake_shedding_locations) &&
                !(J in skip_right_trailing) && # skipped indices
                trailing_vortices # trailing horseshoe vortex

            # check if reflection of right trailing vortex should be included
            include_reflected_right_trailing =
                isnothing(wake_shedding_locations) &&
                (!(J in skip_right_trailing) || keep_reflected) && # skipped indices
                trailing_vortices # trailing horseshoe vortex

            Vhat, Vhat_t, Vhat_b, Vhat_l, Vhat_r = ring_induced_velocity(rcp, surface[j1, j2];
                finite_core = finite_core,
                symmetric = symmetric,
                xhat = xhat,
                top = include_top,
                reflected_top = include_reflected_top,
                bottom = include_bottom,
                reflected_bottom = include_reflected_bottom,
                left = include_left,
                reflected_left = include_reflected_left,
                right = include_right,
                reflected_right = include_reflected_right,
                left_trailing = include_left_trailing,
                reflected_left_trailing = include_reflected_left_trailing,
                right_trailing = include_right_trailing,
                reflected_right_trailing = include_reflected_right_trailing)

            # add contribution from current panel
            if isnothing(Γ)
                Vind += Vhat * surface[j1, j2].gamma
            else
                j = ls[j1, j2]

                Vind += Vhat * Γ[j]

                if derivatives
                    Vind_a += Vhat*Γ_a[j]
                    Vind_b += Vhat*Γ_b[j]
                    Vind_p += Vhat*Γ_p[j]
                    Vind_q += Vhat*Γ_q[j]
                    Vind_r += Vhat*Γ_r[j]
                end
            end

            if !isnothing(wake_shedding_locations)

                J = CartesianIndex(j1+1, j2)

                # add influence of surface-wake interface panel
                panel = surface[j1, j2]
                r11 = bottom_left(panel)
                r12 = bottom_right(panel)
                r21 = wake_shedding_locations[j2]
                r22 = wake_shedding_locations[j2+1]
                core_size = get_core_size(panel)

                Jte = CartesianIndex(j1, j2)
                zleft = r11 == r21
                zright = r12 == r22

                # check if the bottom bound vortex should be included
                include_bottom =
                    !(Jte in skip_bottom && zleft && zright) &&
                    !(J in skip_bottom) && # skipped indices
                    !trailing_vortices && # no trailing horseshoe vortex
                    !skip_trailing_edge # skipped trailing edge

                # check if the reflection of the bottom bound vortex should be included
                include_reflected_bottom =
                    (!(Jte in skip_bottom && zleft && zright) || keep_reflected) &&
                    (!(J in skip_bottom) || keep_reflected) && # skipped indices
                    !trailing_vortices && # no trailing horseshoe vortex
                    !skip_trailing_edge # skipped trailing edge

                # check if left bound vortex should be included
                include_left = !(J in skip_left) && !zleft

                # check if reflection of left bound vortex should be included
                include_reflected_left = (!(J in skip_left) || keep_reflected) && !zleft

                # check if right bound vortex should be included
                include_right = !(J in skip_right) && !zright

                # check if reflection of right bound vortex should be included
                include_reflected_right = (!(J in skip_right) || keep_reflected) && !zright

                # check if left trailing vortex should be included
                include_left_trailing =
                    !(Jte in skip_left_trailing && zleft) &&
                    !(J in skip_left_trailing) && # skipped indices
                    trailing_vortices # trailing horseshoe vortex

                # check if reflection of left trailing vortex should be included
                include_reflected_left_trailing =
                    (!(Jte in skip_left_trailing && zleft) || keep_reflected) &&
                    (!(J in skip_left_trailing) || keep_reflected) && # skipped indices
                    trailing_vortices # trailing horseshoe vortex

                # check if left trailing vortex should be included
                include_right_trailing =
                    !(Jte in skip_right_trailing && zright) &&
                    !(J in skip_right_trailing) && # skipped indices
                    trailing_vortices # trailing horseshoe vortex

                # check if reflection of right trailing vortex should be included
                include_reflected_right_trailing =
                    (!(Jte in skip_right_trailing && zright) || keep_reflected) &&
                    (!(J in skip_right_trailing) || keep_reflected) && # skipped indices
                    trailing_vortices # trailing horseshoe vortex

                # skip top edge because the bottom edge of the trailing edge
                # panel cancels its influence exactly.
                include_top = false
                include_reflected_top = false

                Vhat, Vhat_t, Vhat_b, Vhat_l, Vhat_r = ring_induced_velocity(rcp,
                    r11, r12, r21, r22,
                    finite_core = finite_core,
                    core_size = core_size,
                    symmetric = symmetric,
                    xhat = xhat,
                    top = include_top,
                    reflected_top = include_reflected_top,
                    bottom = include_bottom,
                    reflected_bottom = include_reflected_bottom,
                    left = include_left,
                    reflected_left = include_reflected_left,
                    right = include_right,
                    reflected_right = include_reflected_right,
                    left_trailing = include_left_trailing,
                    reflected_left_trailing = include_reflected_left_trailing,
                    right_trailing = include_right_trailing,
                    reflected_right_trailing = include_reflected_right_trailing)

                # add contribution from interface panel
                if isnothing(Γ)
                    Vind += Vhat * surface[j1, j2].gamma
                else
                    j = ls[j1, j2]

                    Vind += Vhat * Γ[j]

                    if derivatives
                        Vind_a += Vhat*Γ_a[j]
                        Vind_b += Vhat*Γ_b[j]
                        Vind_p += Vhat*Γ_p[j]
                        Vind_q += Vhat*Γ_q[j]
                        Vind_r += Vhat*Γ_r[j]
                    end
                end
            end
        end

    end

    if derivatives
        # pack up derivatives
        dVind = Vind_a, Vind_b, Vind_p, Vind_q, Vind_r

        return Vind, dVind
    else

        return Vind
    end
end

"""
    influence_coefficients!(AIC, surfaces, symmetric, surface_id,
        trailing_vortices, xhat)
    influence_coefficients!(AIC, surfaces, symmetric, surface_id,
        trailing_vortices, xhat, wake_shedding_locations)
    influence_coefficients!(AIC, surfaces, symmetric, surface_id,
        trailing_vortices, xhat, wake_shedding_locations, wakes,
        wake_finite_core, iwake)

Construct the aerodynamic influence coefficient matrix for multiple surfaces.

# Arguments:
 - `AIC`: Influence coefficient matrix
 - `surfaces`: Vector of surfaces, represented by matrices of surface panels
    (see [`SurfacePanel`](@ref) of shape (nc, ns) where `nc` is the number of
    chordwise panels and `ns` is the number of spanwise panels
 - `symmetric`: Flags indicating whether a mirror image (across the X-Z plane) should
    be used when calculating induced velocities. Defaults to `false` for each surface.
 - `surface_id`: ID for each surface.  May be used to deactivate the finite core
    model by setting all surface ID's to the same value.  Defaults to a unique ID
    for each surface
 - `trailing_vortices`: Flags to indicate whether trailing vortices are used for
    each surface.
 - `xhat`: Direction in which trailing vortices are shed if `trailing_vortices = true`.

# Additional Arguments for Including Surface-Wake Transition Panels
 - `wake_shedding_locations`: Wake shedding locations for the trailing edge panels
    of each surface in `surfaces`

# Additional Arguments for Including Wake Panels
 - `wakes`: Vector of wakes, represented by matrices of wake panels (see
    [`WakePanel`](@ref)) of shape (nw, ns) where `nw` is the number of chordwise
    wake panels and `ns` is the number of spanwise panels.
 - `wake_finite_core`: Flag for each wake indicating whether the finite core
    model should be enabled when calculating the wake's influence on itself and
    surfaces/wakes with the same surface ID.
 - `iwake`: Number of wake panels in the chordwise direction to use for each surface.
"""
influence_coefficients!

@inline function influence_coefficients!(AIC, surfaces,
    symmetric, surface_id, trailing_vortices, xhat)
    # number of surfaces
    nsurf = length(surfaces)
    # indices for keeping track of where we are in the AIC matrix
    iAIC = 0
    jAIC = 0
    # loop through receving surfaces
    for i = 1:nsurf
        receiving = surfaces[i]
        # extract number of panels on this receiving surface
        nr = length(receiving) # number of panels on this receiving surface
        # loop through sending surfaces
        jAIC = 0
        for j = 1:nsurf
            sending = surfaces[j]
            # extract number of panels on this sending surface
            ns = length(sending)
            # extract portion of AIC matrix for the two surfaces
            vAIC = view(AIC, iAIC+1:iAIC+nr, jAIC+1:jAIC+ns)
            # check if it's the same surface
            finite_core = surface_id[i] != surface_id[j]
            # populate entries in the AIC matrix
            influence_coefficients!(vAIC, receiving, sending,
                finite_core, symmetric[j], trailing_vortices[j], xhat)
            # increment position in AIC matrix
            jAIC += ns
        end
        # increment position in AIC matrix
        iAIC += nr
    end
    return AIC
end

@inline function influence_coefficients!(AIC, surfaces,
    symmetric, surface_id, trailing_vortices, xhat, wake_shedding_locations)
    # number of surfaces
    nsurf = length(surfaces)
    # indices for keeping track of where we are in the AIC matrix
    iAIC = 0
    jAIC = 0
    # loop through receving surfaces
    for i = 1:nsurf
        receiving = surfaces[i]
        # extract number of panels on this receiving surface
        nr = length(receiving) # number of panels on this receiving surface
        # loop through sending surfaces
        jAIC = 0
        for j = 1:nsurf
            sending = surfaces[j]
            # extract number of panels on this sending surface
            ns = length(sending)
            # extract portion of AIC matrix for the two surfaces
            vAIC = view(AIC, iAIC+1:iAIC+nr, jAIC+1:jAIC+ns)
            # check if it's the same surface
            finite_core = surface_id[i] != surface_id[j]
            # populate entries in the AIC matrix
            influence_coefficients!(vAIC, receiving, sending, finite_core,
                symmetric[j], trailing_vortices[j], xhat, wake_shedding_locations[j])
            # increment position in AIC matrix
            jAIC += ns
        end
        # increment position in AIC matrix
        iAIC += nr
    end
    return AIC
end

@inline function influence_coefficients!(AIC, surfaces,
    symmetric, surface_id, trailing_vortices, xhat, wake_shedding_locations,
    wakes, wake_finite_core, iwake)
    # number of surfaces
    nsurf = length(surfaces)
    # indices for keeping track of where we are in the AIC matrix
    iAIC = 0
    jAIC = 0
    # loop through receving surfaces
    for i = 1:nsurf
        receiving = surfaces[i]
        # extract number of panels on this receiving surface
        nr = length(receiving) # number of panels on this receiving surface
        # loop through sending surfaces
        jAIC = 0
        for j = 1:nsurf
            sending = surfaces[j]
            # extract number of panels on this sending surface
            ns = length(sending)
            # extract portion of AIC matrix for the two surfaces
            vAIC = view(AIC, iAIC+1:iAIC+nr, jAIC+1:jAIC+ns)
            # check if it's the same surface
            finite_core = surface_id[i] != surface_id[j]
            # populate entries in the AIC matrix
            influence_coefficients!(vAIC, receiving, sending, finite_core,
                symmetric[j], trailing_vortices[j], xhat,
                wake_shedding_locations[j], wakes[j], wake_finite_core[j],
                iwake[j])
            # increment position in AIC matrix
            jAIC += ns
        end
        # increment position in AIC matrix
        iAIC += nr
    end
    return AIC
end

@inline function influence_coefficients!(AIC, receiving::AbstractMatrix,
    sending::AbstractMatrix, finite_core, symmetric, trailing_vortices, xhat)

    surface_influence!(AIC, receiving, sending; finite_core,
        symmetric, trailing_vortices, xhat)

    return AIC
end

@inline function influence_coefficients!(AIC, receiving::AbstractMatrix,
    sending::AbstractMatrix, finite_core, symmetric, trailing_vortices, xhat,
    wake_shedding_locations)

    surface_influence!(AIC, receiving, sending; finite_core,
        symmetric, trailing_edge = false, trailing_vortices = false, xhat)

    add_transition_influence!(AIC, receiving, sending, wake_shedding_locations;
        finite_core, symmetric, leading_edge = false, trailing_edge = true,
        trailing_vortices = true, xhat)

    return AIC
end

@inline function influence_coefficients!(AIC, receiving::AbstractMatrix,
    sending::AbstractMatrix, finite_core, symmetric, trailing_vortices, xhat,
    wake_shedding_locations, wake, wake_finite_core, iwake)

    wake_finite_core = finite_core || wake_finite_core

    wake_panels = iwake > 0

    surface_influence!(AIC, receiving, sending; finite_core,
        symmetric, trailing_edge = false, trailing_vortices = false, xhat)

    add_transition_influence!(AIC, receiving, sending, wake_shedding_locations;
        finite_core,
        symmetric,
        leading_edge = false,
        trailing_edge = wake_finite_core || !wake_panels,
        trailing_vortices = trailing_vortices && !wake_panels,
        xhat)

    if wake_panels
        add_wake_influence!(AIC, receiving, sending, wake;
            finite_core = wake_finite_core, symmetric, iwake,
            leading_edge = wake_finite_core, trailing_edge = true,
            trailing_vortices, xhat)
    end

    return AIC
end

"""
    trailing_coefficients!(AIC, surfaces; kwargs...)

Version of [`influence_coefficients!`](@ref) which only updates the influence
coefficients from the trailing edge of each surface.
"""
trailing_coefficients!

@inline function trailing_coefficients!(AIC, surfaces,
    symmetric, surface_id, trailing_vortices, xhat)
    # number of surfaces
    nsurf = length(surfaces)
    # indices for keeping track of where we are in the AIC matrix
    iAIC = 0
    jAIC = 0
    # loop through receving surfaces
    for i = 1:nsurf
        receiving = surfaces[i]
        # extract number of panels on this receiving surface
        nr = length(receiving) # number of panels on this receiving surface
        # loop through sending surfaces
        jAIC = 0
        for j = 1:nsurf
            sending = surfaces[j]
            # extract number of panels on this sending surface
            ns = length(sending)
            # extract portion of AIC matrix for the two surfaces
            vAIC = view(AIC, iAIC+1:iAIC+nr, jAIC+1:jAIC+ns)
            # check if it's the same surface
            finite_core = surface_id[i] != surface_id[j]
            # populate entries in the AIC matrix
            trailing_coefficients!(vAIC, receiving, sending, finite_core,
                symmetric[j], trailing_vortices[j], xhat)
            # increment position in AIC matrix
            jAIC += ns
        end
        # increment position in AIC matrix
        iAIC += nr
    end
    return AIC
end

@inline function trailing_coefficients!(AIC, surfaces,
    symmetric, surface_id, trailing_vortices, xhat, wake_shedding_locations)
    # number of surfaces
    nsurf = length(surfaces)
    # indices for keeping track of where we are in the AIC matrix
    iAIC = 0
    jAIC = 0
    # loop through receving surfaces
    for i = 1:nsurf
        receiving = surfaces[i]
        # extract number of panels on this receiving surface
        nr = length(receiving) # number of panels on this receiving surface
        # loop through sending surfaces
        jAIC = 0
        for j = 1:nsurf
            sending = surfaces[j]
            # extract number of panels on this sending surface
            ns = length(sending)
            # extract portion of AIC matrix for the two surfaces
            vAIC = view(AIC, iAIC+1:iAIC+nr, jAIC+1:jAIC+ns)
            # check if it's the same surface
            finite_core = surface_id[i] != surface_id[j]
            # populate entries in the AIC matrix
            trailing_coefficients!(vAIC, receiving, sending, finite_core,
                symmetric[j], trailing_vortices[j], xhat, wake_shedding_locations[j])
            # increment position in AIC matrix
            jAIC += ns
        end
        # increment position in AIC matrix
        iAIC += nr
    end
    return AIC
end

@inline function trailing_coefficients!(AIC, surfaces,
    symmetric, surface_id, trailing_vortices, xhat, wake_shedding_locations,
    wakes, wake_finite_core, iwake)
    # number of surfaces
    nsurf = length(surfaces)
    # indices for keeping track of where we are in the AIC matrix
    iAIC = 0
    jAIC = 0
    # loop through receving surfaces
    for i = 1:nsurf
        receiving = surfaces[i]
        # extract number of panels on this receiving surface
        nr = length(receiving) # number of panels on this receiving surface
        # loop through sending surfaces
        jAIC = 0
        for j = 1:nsurf
            sending = surfaces[j]
            # extract number of panels on this sending surface
            ns = length(sending)
            # extract portion of AIC matrix for the two surfaces
            vAIC = view(AIC, iAIC+1:iAIC+nr, jAIC+1:jAIC+ns)
            # check if it's the same surface
            finite_core = surface_id[i] != surface_id[j]
            # populate entries in the AIC matrix
            trailing_coefficients!(vAIC, receiving, sending, finite_core,
                symmetric[j], trailing_vortices[j], xhat,
                wake_shedding_locations[j], wakes[j], wake_finite_core[j],
                iwake[j])
            # increment position in AIC matrix
            jAIC += ns
        end
        # increment position in AIC matrix
        iAIC += nr
    end
    return AIC
end

@inline function trailing_coefficients!(AIC, receiving::AbstractMatrix,
    sending::AbstractMatrix, finite_core, symmetric, trailing_vortices, xhat)

    trailing_influence!(AIC, receiving, sending; finite_core,
        symmetric, trailing_vortices, xhat)

    return AIC
end

@inline function trailing_coefficients!(AIC, receiving::AbstractMatrix,
    sending::AbstractMatrix, finite_core, symmetric, trailing_vortices,
    xhat, wake_shedding_locations)

    trailing_influence!(AIC, receiving, sending; finite_core,
        symmetric, trailing_edge = false, trailing_vortices = false, xhat)

    add_transition_influence!(AIC, receiving, sending, wake_shedding_locations;
        finite_core, symmetric, leading_edge = false, trailing_edge = true,
        trailing_vortices = true, xhat)

    return AIC
end

@inline function trailing_coefficients!(AIC, receiving::AbstractMatrix,
    sending::AbstractMatrix, finite_core, symmetric, trailing_vortices, xhat,
    wake_shedding_locations, wake, wake_finite_core, iwake)

    wake_finite_core = finite_core || wake_finite_core

    wake_panels = iwake > 0

    trailing_influence!(AIC, receiving, sending; finite_core,
        symmetric, trailing_edge = false, trailing_vortices = false, xhat)

    add_transition_influence!(AIC, receiving, sending, wake_shedding_locations;
        finite_core,
        symmetric,
        leading_edge = false,
        trailing_edge = wake_finite_core || !wake_panels,
        trailing_vortices = trailing_vortices && !wake_panels,
        xhat)

    if wake_panels
        add_wake_influence!(AIC, receiving, sending, wake;
            finite_core = wake_finite_core, symmetric, iwake,
            leading_edge = wake_finite_core, trailing_edge = true,
            trailing_vortices, xhat)
    end

    return AIC
end

# surfaces only
@inline function surface_influence!(AIC, receiving, sending; finite_core,
    symmetric, trailing_edge = true, trailing_vortices, xhat)

    # get sending surface dimensions
    nc, ns = size(sending)
    ls = LinearIndices(sending)

    # check if we can reuse surface edges
    reuse_edges = !finite_core

    # loop over receiving panels
    for i in eachindex(receiving)

        # control point location
        rcp = controlpoint(receiving[i])

        # normal vector body axis
        nhat = normal(receiving[i])

        if reuse_edges
            # use more efficient loop when we can reuse edges
            for j2 in 1:ns, j1 in 1:nc
                first_panel = j1 == 1
                last_panel = j1 == nc
                left_panel = j2 == 1
                right_panel = j2 == ns

                include_right = right_panel
                include_bottom = last_panel && trailing_edge && !trailing_vortices
                include_left_trailing = last_panel && trailing_vortices
                include_right_trailing = right_panel && last_panel && trailing_vortices

                # compute induced velocity
                Vhat, Vhat_t, Vhat_b, Vhat_l, Vhat_r = ring_induced_velocity(
                    rcp, sending[j1, j2];
                    finite_core = finite_core,
                    symmetric = symmetric,
                    xhat = xhat,
                    bottom = include_bottom,
                    reflected_bottom = include_bottom,
                    right = include_right,
                    reflected_right = include_right,
                    left_trailing = include_left_trailing,
                    reflected_left_trailing = include_left_trailing,
                    right_trailing = include_right_trailing,
                    reflected_right_trailing = include_right_trailing)

                # add partial contribution from current panel
                AIC[i,ls[j1, j2]] = dot(Vhat, nhat)

                # add partial contribution from panel above this one (if applicable)
                if !first_panel
                    AIC[i,ls[j1-1, j2]] += dot(Vhat_t, nhat)
                end

                # add partial contribution from panel to the left (if applicable)
                if !left_panel
                    AIC[i,ls[j1, j2-1]] += dot(Vhat_l, nhat)
                end
            end
        else
            # we can't reuse edges, probably because the finite-core model is active
            for j2 in 1:ns, j1 in 1:nc
                last_panel = j1 == nc

                include_bottom = last_panel && trailing_edge && !trailing_vortices
                include_trailing = last_panel && trailing_vortices

                # compute induced velocity
                Vhat, Vhat_t, Vhat_b, Vhat_l, Vhat_r = ring_induced_velocity(
                    rcp, sending[j1, j2];
                    finite_core = finite_core,
                    symmetric = symmetric,
                    xhat = xhat,
                    bottom = include_bottom,
                    reflected_bottom = include_bottom,
                    left_trailing = include_trailing,
                    reflected_left_trailing = include_trailing,
                    right_trailing = include_trailing,
                    reflected_right_trailing = include_trailing)

                # add to AIC matrix
                j = ls[j1, j2]
                AIC[i,j] = dot(Vhat, nhat)
            end
        end
    end

    return AIC
end

# trailing edge panels only
@inline function trailing_influence!(AIC, receiving, sending; finite_core,
    symmetric, trailing_edge = true, trailing_vortices, xhat)

    # get sending surface dimensions
    nc, ns = size(sending)
    ls = LinearIndices(sending)

    # check if we can reuse surface edges
    reuse_edges = !finite_core

    # loop over receiving panels
    for i in eachindex(receiving)

        # control point location
        rcp = controlpoint(receiving[i])

        # normal vector body axis
        nhat = normal(receiving[i])

        if reuse_edges
            # use more efficient loop when we can reuse edges
            j1 = nc
            for j2 in 1:ns
                first_panel = j1 == 1
                last_panel = j1 == nc
                left_panel = j2 == 1
                right_panel = j2 == ns

                include_right = right_panel
                include_bottom = last_panel && trailing_edge && !trailing_vortices
                include_left_trailing = last_panel && trailing_vortices
                include_right_trailing = right_panel && last_panel && trailing_vortices

                # compute induced velocity
                Vhat, Vhat_t, Vhat_b, Vhat_l, Vhat_r = ring_induced_velocity(
                    rcp, sending[j1, j2];
                    finite_core = finite_core,
                    symmetric = symmetric,
                    xhat = xhat,
                    bottom = include_bottom,
                    reflected_bottom = include_bottom,
                    right = include_right,
                    reflected_right = include_right,
                    left_trailing = include_left_trailing,
                    reflected_left_trailing = include_left_trailing,
                    right_trailing = include_right_trailing,
                    reflected_right_trailing = include_right_trailing)

                # add partial contribution from current panel
                AIC[i,ls[j1, j2]] = dot(Vhat, nhat)

                # add partial contribution from panel above this one (if applicable)
                if !first_panel
                    AIC[i,ls[j1-1, j2]] += dot(Vhat_t, nhat)
                end

                # add partial contribution from panel to the left (if applicable)
                if !left_panel
                    AIC[i,ls[j1, j2-1]] += dot(Vhat_l, nhat)
                end
            end
        else
            # we can't reuse edges, probably because the finite-core model is active
            j1 = nc
            for j2 in 1:ns
                last_panel = j1 == nc

                include_bottom = last_panel && trailing_edge && !trailing_vortices
                include_trailing = last_panel && trailing_vortices

                # compute induced velocity
                Vhat, Vhat_t, Vhat_b, Vhat_l, Vhat_r = ring_induced_velocity(
                    rcp, sending[j1, j2];
                    finite_core = finite_core,
                    symmetric = symmetric,
                    xhat = xhat,
                    bottom = include_bottom,
                    reflected_bottom = include_bottom,
                    left_trailing = include_trailing,
                    reflected_left_trailing = include_trailing,
                    right_trailing = include_trailing,
                    reflected_right_trailing = include_trailing)

                # add to AIC matrix
                j = ls[j1, j2]
                AIC[i,j] = dot(Vhat, nhat)
            end
        end
    end

    return AIC
end

# transition panel only
@inline function add_transition_influence!(AIC, receiving, sending, wake_shedding_locations;
    finite_core, symmetric, leading_edge=true, trailing_edge=true,
    trailing_vortices, xhat)

    # get sending surface dimensions
    nc, ns = size(sending)
    ls = LinearIndices(sending)

    # determine control flow parameters based on inputs
    reuse_edges = !finite_core

    # loop over receiving panels
    for i in eachindex(receiving)

        # control point location
        rcp = controlpoint(receiving[i])

        # normal vector body axis
        nhat = normal(receiving[i])

        if reuse_edges
            # use more efficient loop when we can reuse edges
            j1 = nc
            for j2 in 1:ns

                # surface-wake interface panel coordinates
                panel = sending[j1, j2]
                r11 = bottom_left(panel)
                r12 = bottom_right(panel)
                r21 = wake_shedding_locations[j2]
                r22 = wake_shedding_locations[j2+1]
                core_size = get_core_size(panel)

                # location of panel
                left_panel = j2 == 1
                right_panel = j2 == ns

                include_top = leading_edge
                include_bottom = trailing_edge && !trailing_vortices
                include_left = r11 != r21
                include_right = r12 != r22 && right_panel
                include_left_trailing = trailing_vortices
                include_right_trailing = right_panel && trailing_vortices

                Vhat, Vhat_t, Vhat_b, Vhat_l, Vhat_r = ring_induced_velocity(rcp,
                    r11, r12, r21, r22;
                    finite_core = finite_core,
                    core_size = core_size,
                    symmetric = symmetric,
                    xhat = xhat,
                    top = include_top,
                    reflected_top = include_top,
                    bottom = include_bottom,
                    reflected_bottom = include_bottom,
                    left = include_left,
                    reflected_left = include_left,
                    right = include_right,
                    reflected_right = include_right,
                    left_trailing = include_left_trailing,
                    reflected_left_trailing = include_left_trailing,
                    right_trailing = include_right_trailing,
                    reflected_right_trailing = include_right_trailing)

                # add contribution to current panel influence
                AIC[i,ls[j1, j2]] += dot(Vhat, nhat)

                # add partial contribution from panel to the left
                if !left_panel
                    AIC[i,ls[j1, j2-1]] += dot(Vhat_l, nhat)
                end
            end
        else
            # we can't reuse edges
            j1 = nc
            for j2 in 1:ns

                # surface-wake interface panel coordinates
                panel = sending[j1, j2]
                r11 = bottom_left(panel)
                r12 = bottom_right(panel)
                r21 = wake_shedding_locations[j2]
                r22 = wake_shedding_locations[j2+1]
                core_size = get_core_size(panel)

                include_top = leading_edge
                include_bottom = trailing_edge && !trailing_vortices
                include_left = r11 != r21
                include_right = r12 != r22
                include_left_trailing = trailing_vortices
                include_right_trailing = trailing_vortices

                Vhat, Vhat_t, Vhat_b, Vhat_l, Vhat_r = ring_induced_velocity(rcp,
                    r11, r12, r21, r22;
                    finite_core = finite_core,
                    core_size = core_size,
                    symmetric = symmetric,
                    xhat = xhat,
                    top = include_top,
                    reflected_top = include_top,
                    bottom = include_bottom,
                    reflected_bottom = include_bottom,
                    left = include_left,
                    reflected_left = include_left,
                    right = include_right,
                    reflected_right = include_right,
                    left_trailing = include_left_trailing,
                    reflected_left_trailing = include_left_trailing,
                    right_trailing = include_right_trailing,
                    reflected_right_trailing = include_right_trailing)

                # add contribution to AIC matrix
                AIC[i,ls[j1, j2]] += dot(Vhat, nhat)
            end
        end
    end

    return AIC
end

# wake panels only
@inline function add_wake_influence!(AIC, receiving, sending, sending_wake;
    finite_core, symmetric, iwake, leading_edge = true, trailing_edge = true,
    trailing_vortices, xhat)

    # get sending surface dimensions
    nc, ns = size(sending)
    ls = LinearIndices(sending)

    # determine control flow parameters based on inputs
    reuse_edges = !finite_core

    # loop over receiving panels
    for i in eachindex(receiving)

        # control point location
        rcp = controlpoint(receiving[i])

        # normal vector body axis
        nhat = normal(receiving[i])

        if reuse_edges

            # use more efficient loop when we can reuse edges
            j1 = nc
            for j2 in 1:ns, iw = 1:iwake
                first_panel = iw == 1
                last_panel = iw == iwake
                left_panel = j2 == 1
                right_panel = j2 == ns

                include_top = first_panel && leading_edge
                include_bottom = last_panel && trailing_edge && !trailing_vortices
                include_left = true
                include_right = right_panel
                include_left_trailing = last_panel && trailing_vortices
                include_right_trailing = right_panel && last_panel && trailing_vortices

                Vhat, Vhat_t, Vhat_b, Vhat_l, Vhat_r = ring_induced_velocity(
                    rcp, wake[iw, j2];
                    finite_core = finite_core,
                    symmetric = symmetric,
                    xhat = xhat,
                    top = include_top,
                    reflected_top = include_top,
                    bottom = include_bottom,
                    reflected_bottom = include_bottom,
                    left = include_left,
                    reflected_left = include_left,
                    right = include_right,
                    reflected_right = include_right,
                    left_trailing = include_left_trailing,
                    reflected_left_trailing = include_left_trailing,
                    right_trailing = include_right_trailing,
                    reflected_right_trailing = include_right_trailing)

                # add partial contribution from current panel
                AIC[i,ls[j1, j2]] += dot(Vhat, nhat)

                # add partial contribution from panel to the left
                if !left_panel
                    AIC[i,ls[j1, j2-1]] += dot(Vhat_l, nhat)
                end
            end
        else
            # we can't re-use edges

            j1 = nc
            for j2 in 1:ns, iw = 1:iwake
                first_panel = iw == 1
                last_panel = iw == iwake

                include_top = !first_panel || (first_panel && leading_edge)
                include_bottom = !last_panel || (last_panel && trailing_edge)
                include_trailing = last_panel && trailing_vortices

                # compute induced velocity
                Vhat, Vhat_t, Vhat_b, Vhat_l, Vhat_r = ring_induced_velocity(
                    rcp, wake[iw, j2];
                    finite_core = wake_finite_core || finite_core,
                    symmetric = symmetric,
                    xhat = xhat,
                    top = include_top,
                    reflected_top = include_top,
                    bottom = include_bottom,
                    reflected_bottom = include_bottom,
                    left_trailing = include_trailing,
                    reflected_left_trailing = include_trailing,
                    right_trailing = include_trailing,
                    reflected_right_trailing = include_trailing)

                # add to AIC matrix
                j = ls[j1, j2]
                AIC[i,j] += dot(Vhat, nhat)
            end
        end
    end
    return AIC
end
