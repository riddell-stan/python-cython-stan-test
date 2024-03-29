# distutils: language=c++
# cython: language_level=3
# cython: binding=True
"""Functions wrapping stan::services functions.

The functions in this module are all thin wrappers of stan::services function.
The functions lack documentation because they are all essentially the same.
With minor exceptions, the signature of each function is identical to the
signature of the function in stan::services with the same name. The differences
between the two functions include:

- a Python dictionary is passed instead of a ``var_context``.
- output of all writers is added to a single boost::spsc_queue

This Cython file has `binding=True` in order to allow the signatures of
functions defined here to be inspected.
"""

cimport cython.operator.dereference as deref
cimport libcpp
from libcpp.string cimport string
from libcpp.vector cimport vector

cimport python_cython_stan_test.boost as boost
cimport python_cython_stan_test.stan as stan

import queue

import python_cython_stan_test.utils


cdef extern from "normal.hpp" nogil:
    cdef cppclass stan_model:
        stan_model(stan.var_context& var_context) except +
        stan_model(stan.var_context& var_context, unsigned int random_seed) except +
        void get_param_names(vector[string]&)
        void get_dims(vector[vector[size_t]]&)
        void constrained_param_names(vector[string]&)


cdef class SPSCQueue:
    """Python interface to spsc_queue[string].

    Interface only exposes methods for retrieving data.

    See boost documentation for spsc_queue for more information.

    """
    cdef boost.spsc_queue[string] * queue_ptr  # holds pointer to spsc_queue

    def __cinit__(self, int capacity):
        self.queue_ptr = new boost.spsc_queue[string](capacity)

    def get_nowait(self):
        """Mimics the interface of Python's queue.Queue's get_nowait."""
        cdef string message
        if self.queue_ptr.pop(message):
            return message
        else:
            raise queue.Empty

    def __dealloc__(self):
        del self.queue_ptr


cdef stan.array_var_context * make_array_var_context(dict data):
    """Returns a pointer to a new array_var_context.

    See the C++ documentation for ``array_var_context`` for details about the
    C++ class.

    Caller takes responsibility for ``free``ing. This is not good C++ practice
    but Cython will not allow stack allocation unless a C++ class has a nullary
    constructor.

    """
    names_r_, values_r_, dim_r_, names_i_, values_i_, dim_i_ = python_cython_stan_test.utils._split_data(data)
    cdef vector[string] names_r = names_r_
    cdef vector[double] values_r = values_r_
    cdef vector[vector[size_t]] dim_r = dim_r_

    cdef vector[string] names_i = names_i_
    cdef vector[int] values_i = values_i_
    cdef vector[vector[size_t]] dim_i = dim_i_

    cdef stan.array_var_context * var_context_ptr = new stan.array_var_context(names_r, values_r, dim_r, names_i, values_i, dim_i)
    return var_context_ptr


def param_names(dict data):
    """Call the ``get_params`` method of the ``stan_model``."""
    cdef stan.array_var_context * var_context_ptr = make_array_var_context(data)
    cdef stan_model * model = new stan_model(deref(var_context_ptr))

    cdef vector[string] names
    model.get_param_names(names)

    del model
    del var_context_ptr

    return names


def constrained_param_names(dict data):
    """Call the ``constrained_param_names`` method of the ``stan_model``."""
    cdef stan.array_var_context * var_context_ptr = make_array_var_context(data)
    cdef stan_model * model = new stan_model(deref(var_context_ptr))

    cdef vector[string] names
    model.constrained_param_names(names)

    del model
    del var_context_ptr

    return names


def dims(dict data):
    """Call the ``get_dims`` method of the ``stan_model``."""
    cdef stan.array_var_context * var_context_ptr = make_array_var_context(data)
    cdef stan_model * model = new stan_model(deref(var_context_ptr))

    cdef vector[vector[size_t]] dims_
    model.get_dims(dims_)

    del model
    del var_context_ptr

    return dims_


def hmc_nuts_diag_e_adapt_wrapper(dict data, SPSCQueue queue,
                                  int random_seed, int chain, double init_radius,
                                  int num_warmup, int num_samples, int num_thin, libcpp.bool save_warmup,
                                  int refresh, double stepsize, double stepsize_jitter, int max_depth,
                                  double delta, double gamma, double kappa, double t0, int init_buffer,
                                  int term_buffer, int window):
    # An instance of ChainableStack must be created in each thread. Without
    # creating such an instance, use of a stan model instance is not threadsafe.
    # See documentation in stan/math/rev/core/autodiffstackstorage.hpp for details.
    cdef stan.ChainableStack thread_instance
    # The following line is prevent Cython from ignoring the previous line. Without the following line
    # Cython will think that `thread_instance` is not used and elide the declaration. But we need
    # the declaration in order to use Stan in a threadsafe manner.
    cdef stan.ChainableStack * thread_instance_ptr = &thread_instance
    cdef int return_code
    cdef stan.array_var_context * var_context_ptr = make_array_var_context(data)
    cdef boost.spsc_queue[string] * queue_ptr = queue.queue_ptr
    cdef stan.var_context * init_var_context = new stan.empty_var_context()
    cdef stan_model * model = new stan_model(deref(var_context_ptr), <unsigned int> random_seed)
    cdef stan.interrupt interrupt
    cdef stan.logger * logger = new stan.queue_logger(queue_ptr, b'logger:')
    cdef stan.writer * init_writer = new stan.queue_writer(queue_ptr, b'init_writer:')
    cdef stan.writer * sample_writer = new stan.queue_writer(queue_ptr, b'sample_writer:')
    cdef stan.writer * diagnostic_writer = new stan.queue_writer(queue_ptr, b'diagnostic_writer:')
    with nogil:
        return_code = stan.hmc_nuts_diag_e_adapt(deref(model), deref(init_var_context), random_seed, chain, init_radius,
                                                 num_warmup, num_samples, num_thin, save_warmup,
                                                 refresh, stepsize, stepsize_jitter, max_depth,
                                                 delta, gamma, kappa, t0, init_buffer, term_buffer, window,
                                                 interrupt, deref(logger), deref(init_writer),
                                                 deref(sample_writer), deref(diagnostic_writer))
    del model
    del init_var_context
    del logger
    del init_writer
    del diagnostic_writer
    del var_context_ptr
    return return_code
