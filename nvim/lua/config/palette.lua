-- Color roles, shared by syntax, semantic tokens and interactive surfaces.
-- Rationale and measured contrast are documented in nvim/DESIGN.md.
return {
  canvas = '#000000', panel = '#101116', inset = '#08090D', selection = '#24212C',
  text = '#D7E3FF', muted = '#98A2B8', punctuation = '#A9B9D6',
  focus = '#FF4057', variable = '#FF4057', parameter = '#FFD4A8', member = '#E0C6FF',
  callable = '#70D7FF', keyword = '#C7A6FF', type = '#FFD166',
  string = '#7FE3C2', literal = '#FFB47D', comment = '#98A2B8',
  folder = '#70D7FF', path = '#A9B9D6',
  error = '#FF8FA3', warning = '#FFD166', info = '#70D7FF', success = '#7FE3C2',
}
