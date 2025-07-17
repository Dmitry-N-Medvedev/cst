pub const EOL = enum {
    /// Old MacOS
    R,
    /// Unix/Linux/Modern MacOS
    N,
    /// Windows
    RN,

    pub fn value(self: EOL) []const u8 {
        return switch (self) {
            .R => "\r",
            .N => "\n",
            .RN => "\r\n",
        };
    }
};
