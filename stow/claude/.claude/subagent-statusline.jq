def icon: {running:"\u001b[94m●\u001b[0m", completed:"\u001b[32m✓\u001b[0m", failed:"\u001b[31m✗\u001b[0m", killed:"\u001b[2m■\u001b[0m"}[.status] // "?";
def dur: ((now*1000 - .startTime)/1000 | floor) as $s | if $s < 60 then "\($s)s" else "\($s/60|floor)m\($s%60)s" end;
def ctx: if .contextWindowSize then " \((.tokenCount // 0) * 100 / .contextWindowSize | floor)%" else "" end;
def spark: (.tokenSamples // []) as $t | if ($t|length) < 2 then "" else
  ([range(1; $t|length) | $t[.] - $t[.-1]]) as $d | ($d|max) as $mx |
  " " + ($d | map(if $mx <= 0 then "▁" else ["▁","▂","▃","▄","▅","▆","▇","█"][(. * 7 / $mx | floor | if . < 0 then 0 else . end)] end) | join("")) end;
.tasks[] | {id, content: "\(icon) \(.name // .agentType // .description) \u001b[2m· \(.model // "-")\(if .effort then "/\(.effort)" else "" end) · \(dur) · \((.tokenCount // 0)/1000|floor)k\(ctx)\(spark) · \(.cwd // "" | split("/") | last // "")\u001b[0m"}
