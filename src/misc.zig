pub inline fn sliceFromArray(array: anytype) []const @typeInfo(@TypeOf(array)).array.child {
    return array[0..@typeInfo(@TypeOf(array)).array.len];
}
