import os
from setuptools import setup
import setuptools

from Cython.Build import cythonize

source_dir = 'python_cython_stan_test'
include_dirs = [
    source_dir,
    os.path.join(source_dir, "lib", "stan", "src"),
    os.path.join(source_dir, "lib", "stan", "lib", "stan_math"),
    os.path.join(source_dir, "lib", "stan", "lib", "stan_math", "lib", "eigen_3.3.3"),
    os.path.join(source_dir, "lib", "stan", "lib", "stan_math", "lib", "boost_1.69.0"),
    os.path.join(
        source_dir, "lib", "stan", "lib", "stan_math", "lib", "sundials_4.1.0", "include"
    ),
]
stan_macros = [
    ("BOOST_DISABLE_ASSERTS", None),
    ("BOOST_PHOENIX_NO_VARIADIC_EXPRESSION", None),
    ("STAN_THREADS", None),
]
extra_compile_args = ["-std=c++1y"]
cython_include_path = [source_dir]

extension = setuptools.Extension(
    "python_cython_stan_test.normal",
    language="c++",
    sources=[os.path.join("python_cython_stan_test", "normal.pyx")],
    define_macros=stan_macros,
    include_dirs=include_dirs,
    extra_compile_args=extra_compile_args,
)


setup(
    name="python_cython_stan_test",
    version=1.0,
    python_requires=">=3.6",
    license="MIT",
    long_description="static init",
    long_description_content_type="text/markdown",
    packages=['python_cython_stan_test'],
    install_requires=['numpy'],
    ext_modules=cythonize(
        [extension],
        include_path=cython_include_path,
        quiet=False,
    ),
)
