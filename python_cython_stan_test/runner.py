import sys
import python_cython_stan_test.normal as normal
import python_cython_stan_test.services.arguments as arguments


if __name__ == "__main__":
    queue_wrapper = normal.SPSCQueue(capacity=10_000_000)
    function_basename = "hmc_nuts_diag_e_adapt_wrapper"
    function_wrapper = normal.hmc_nuts_diag_e_adapt_wrapper

    # Fetch defaults for missing arguments. This is an important piece!
    # For example, `random_seed`, if not in `kwargs`, will be set.

    # exclude {"data", "queue"} from arguments
    function_arguments = "random_seed chain init_radius num_warmup num_samples num_thin save_warmup refresh stepsize stepsize_jitter max_depth delta gamma kappa t0 init_buffer term_buffer window".split()

    # This is clumsy due to the way default values are available. There is no
    # way to directly lookup the default value for an argument (e.g., `delta`)
    # given both the argument name and the (full) function name (e.g.,
    # `stan::services::hmc_nuts_diag_e_adapt`).
    kwargs = {}
    for arg in function_arguments:
        if arg not in kwargs:
            kwargs[arg] = arguments.lookup_default(arguments.Method["SAMPLE"], arg)
    print(kwargs)
    data = {}
    function_wrapper(data, queue_wrapper, **kwargs)
    print("success")
    sys.exit(0)
