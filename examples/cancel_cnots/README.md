### Comparing cancelling CNOTs with Julia and Python implementations

#### Julia
```julia
julia> @btime make_cnot_circuit();
  5.553 μs (151 allocations: 11.41 KiB)

julia> @btime make_and_cancel()
  24.888 μs (417 allocations: 30.25 KiB)
```

#### Python

```python
In [2]: %timeit make_cnot_circuit(); None;
247 µs ± 1.18 µs per loop (mean ± std. dev. of 7 runs, 1,000 loops each)

In [3]: %timeit make_and_cancel()
657 µs ± 1.64 µs per loop (mean ± std. dev. of 7 runs, 1,000 loops each)
```
