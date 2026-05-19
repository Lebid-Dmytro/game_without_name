# Call scenarios catalog (20)

| # | File | Type | Anomaly | Camera | Correct actions |
|---|------|------|---------|--------|-----------------|
| 01 | faceless_tenant | suspicious | faceless_tenant | floor_4 | dispatch, lock_floor |
| 02 | wrong_apartment | suspicious | wrong_apartment_number | floor_4 | lock_floor, quarantine |
| 03 | endless_staircase | active | endless_staircase | staircase | lock_floor, cut_power |
| 04 | duplicate_person | suspicious | duplicate_person | floor_2 | dispatch, quarantine |
| 05 | corridor_expansion | active | corridor_expansion | floor_2 | lock_floor, cut_power |
| 06 | normal_leak | normal | — | lobby | ignore, dispatch |
| 07 | mimic_call | mimic | corridor_expansion | floor_2 | lock_floor, cut_power |
| 08 | fake_child | active | fake_child_voice | floor_2 | quarantine, lock_floor |
| 09 | elevator_anomaly | suspicious | faceless_tenant | elevator | dispatch, cut_power |
| 10 | loud_neighbor | normal | — | floor_4 | ignore, dispatch |
| 11 | lobby_visitor | suspicious | faceless_tenant | lobby | dispatch, quarantine |
| 12 | stairwell_jogger | normal | — | staircase | ignore, dispatch |
| 13 | brownout_complaint | normal | — | floor_2 | ignore, dispatch |
| 14 | two_uncles | active | duplicate_person | floor_2 | dispatch, quarantine |
| 15 | relabeled_door | suspicious | wrong_apartment_number | floor_4 | lock_floor, quarantine |
| 16 | elevator_breathing | active | faceless_tenant | elevator | cut_power, dispatch |
| 17 | mimic_supervisor | mimic | corridor_expansion | floor_2 | lock_floor, quarantine |
| 18 | guard_stairs | active | endless_staircase | staircase | lock_floor, cut_power |
| 19 | long_hall | suspicious | corridor_expansion | floor_4 | lock_floor, cut_power |
| 20 | child_laugh | mimic | fake_child_voice | floor_2 | quarantine, lock_floor |

**Per shift:** `CallManager.scenarios_per_shift` (default 7) picks randomly from this pool.

**Add #21+:** copy any JSON, change `id`, keep `anomaly_id` aligned with `AnomalyRegistry`.
