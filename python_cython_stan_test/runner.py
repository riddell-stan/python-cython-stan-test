import sys
import time
import threading


def task():
    import python_cython_stan_test.normal as normal
    queue_wrapper = normal.SPSCQueue(capacity=10_000_000)
    function_basename = "hmc_nuts_diag_e_adapt_wrapper"
    function_wrapper = normal.hmc_nuts_diag_e_adapt_wrapper

    kwargs = {'random_seed': 1, 'chain': 1, 'init_radius': 2, 'num_warmup': 100,
              'num_samples': 100, 'num_thin': 1, 'save_warmup': False,
              'refresh': 10, 'stepsize': 1.0, 'stepsize_jitter': 0.0,
              'max_depth': 10, 'delta': 0.8, 'gamma': 0.05, 'kappa': 0.75, 't0':
              10.0, 'init_buffer': 75, 'term_buffer': 50, 'window': 25}

    data = {}
    function_wrapper(data, queue_wrapper, **kwargs)
    time.sleep(1)
    return


if __name__ == "__main__":
    threads = []
    for _ in range(4):
        th = threading.Thread(target=task)
        th.start()
        threads.append(th)
    for th in threads:
        th.join()
    print("success")
    sys.exit(0)
