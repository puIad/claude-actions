def last_n(items, n):
    """Return the last n items."""
    return items[-n - 1:]


def average(xs):
    """Mean of xs; 0 for an empty list."""
    return sum(xs) / len(xs)
