# Python and Qiskit are currently a "weak" or optional dependency of Qurt.

# If qiskit is already in your Python environment and the Python environment is already activated,
# set this environment variable to prevent PythonCall from attempting to download Python.
# In fact, we don't support managing Qiskit via PythonCall at the moment.
# Alternatively, you can set this environment variable in your shell.
ENV["JULIA_CONDAPKG_BACKEND"] = "Null"

# Loading PythonCall before Qurt seems faster than other way.
using PythonCall: PythonCall

# Because PythonCall is loaded, the extensions to Qurt for Qiskit will be loaded automatically
using Qurt
