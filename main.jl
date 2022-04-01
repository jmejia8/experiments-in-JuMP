@info "Loading deps..."
using JuMP
using MathOptInterface
using GLPK
using HiGHS
using DataFrames
import CSV

function load_mps(fname)
    if !isfile(fname)
        error("File " * fname * " not found")
    end
 
    @info "Loading model..."
    return read_from_file(fname)
end

function configure_optimizer(model)
    @info "Setting optimizer"
    
    # set_optimizer(model, GLPK.Optimizer)
    set_optimizer(model, HiGHS.Optimizer)
 
    set_optimizer_attribute(model, "presolve", "on") # OK
    # set_optimizer_attribute(model, "mip_heuristic_effort", 0.5)

    set_optimizer_attribute(model, "mip_rel_gap", 0.5) # OK
    set_optimizer_attribute(model, "mip_abs_gap", 1.0) # OK


    set_optimizer_attribute(model, "parallel", "on")
    set_optimizer_attribute(model, "threads", 4) # OK but update number

    # set_optimizer_attribute(model, "time_limit", 30.0)
end

function configure_optimizer_glpk(model)
    @info "Setting optimizer"
    
    set_optimizer(model, GLPK.Optimizer)
 
end

function save_variables(model, fname)
    @info "Saving results."
    x = all_variables(model)
    df = DataFrame(
              :variable => x,
              :value => value.(x),
             )
    
    CSV.write(fname*".csv", df)
end


function main()
    # set here your data file name
    fname = "data/gpscheduler.mps"

    model = load_mps(fname)
    configure_optimizer(model)

    @info "Optimizing"
    optimize!(model)
    @info "Done!"

    if termination_status(model) != MathOptInterface.OPTIMAL
        @warn "Optimal solution not found 😱"
        return
    end

    save_variables(model, fname)

    return model
    
end

main()
