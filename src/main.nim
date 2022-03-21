# import strutils, system
# import strformat
# type Sample = ref object of RootObj
#   x: int
# proc call(self: Sample, a: int): void =
#     echo fmt"Sample: {a}"

# method call2(self: Sample, a: int): void {.base.} =
#     echo fmt"Sample: {a}"

# func call3(self: Sample, a: int): string =
#     return fmt"Sample: {a}"

# Sample().call(1)
# Sample().call 2
# Sample().call2 3
# echo Sample().call3 4
# let temp = Sample()
# temp.x = 1

# type 
#   NilableSample = ref object
#     x, y: string
#   Sample2 = NilableSample not nil  # これはNot Nil制約