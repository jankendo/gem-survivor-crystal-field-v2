# Arena Render Cache Architecture

## 構造

Arenaは単一CanvasItemを維持し、static terrainをprecomputed draw dataとして分離する。SceneTreeや敵Nodeを増やさず、corridor、room、boundaryの可視rect、biome、surface、fallback色を`terrain_draw_cache`へ保存する。

動的なplayer、enemy、projectile、gem、drop、effect、warning、HPは毎フレーム描画する。static cacheはsimulation source of truthではない。

## 無効化

cache keyは次を含む。

* camera tile
* viewport size / orientation
* camera zoom / UI scale相当
* map seed
* corridor / room / boundary件数
* renderer
* environment quality profile
* texture enabled / alpha

`bind_state()`、mobile layout変更、明示`invalidate_static_cache()`でも破棄する。map内容の差し替えはstate rebindまたはmap生成時のinvalidateを必須とする。

## Minimap

minimap contentの更新上限は8Hzで、expanded mapの表示状態とは独立する。ベンチマークはheadless SceneTreeの描画が1秒に1回だけ進むため60回となり、実画面の8Hz上限証明ではない。cadence値と経過時間判定はunit/UIテストで確認する。

## Before / After

60秒合成計測のstatic terrain rebuildは60回から14回へ減少し、76.67%削減した。tile draw submission自体は30,622から30,560であり、今回の改善対象はgeometry/biome command再構築のCPU負荷である。SubViewportやstatic CanvasItem分離によるGPU submission削減は将来候補として残す。
