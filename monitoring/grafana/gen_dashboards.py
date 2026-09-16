import json, os, itertools

DS = {"type": "prometheus", "uid": "prometheus"}
OUT = "monitoring/grafana/dashboards"

_id = itertools.count(1)


def panel(title, ptype, exprs, x, y, w, h, unit=None, thresholds=None, desc="", maxv=None):
    tgts = []
    for i, (e, lg) in enumerate(exprs):
        tgts.append({"datasource": DS, "editorMode": "code", "expr": e,
                     "legendFormat": lg, "range": True, "refId": chr(65 + i)})
    custom = {}
    if ptype == "timeseries":
        custom = {"drawStyle": "line", "fillOpacity": 12, "lineWidth": 2,
                  "showPoints": "never", "spanNulls": True}
    fc = {"color": {"mode": "palette-classic"}, "custom": custom, "mappings": []}
    if ptype in ("stat", "gauge"):
        fc["color"] = {"mode": "thresholds"}
    if unit:
        fc["unit"] = unit
    if maxv is not None:
        fc["max"] = maxv
        fc["min"] = 0
    fc["thresholds"] = {"mode": "absolute",
                        "steps": thresholds or [{"color": "green", "value": None}]}
    p = {"id": next(_id), "type": ptype, "title": title, "description": desc,
         "datasource": DS, "gridPos": {"h": h, "w": w, "x": x, "y": y},
         "targets": tgts, "fieldConfig": {"defaults": fc, "overrides": []},
         "options": {}}
    if ptype == "stat":
        p["options"] = {"colorMode": "background", "graphMode": "area",
                        "justifyMode": "auto", "orientation": "auto",
                        "reduceOptions": {"calcs": ["lastNotNull"], "fields": "", "values": False},
                        "textMode": "auto"}
    elif ptype == "gauge":
        p["options"] = {"showThresholdLabels": False, "showThresholdMarkers": True,
                        "reduceOptions": {"calcs": ["lastNotNull"], "fields": "", "values": False}}
    elif ptype == "timeseries":
        p["options"] = {"legend": {"displayMode": "list", "placement": "bottom", "showLegend": True},
                        "tooltip": {"mode": "multi", "sort": "desc"}}
    return p


def dashboard(uid, title, tags, panels, desc=""):
    return {"annotations": {"list": []}, "editable": True, "description": desc,
            "graphTooltip": 1, "panels": panels, "refresh": "30s", "schemaVersion": 39,
            "tags": tags, "templating": {"list": []},
            "time": {"from": "now-6h", "to": "now"}, "timezone": "browser",
            "title": title, "uid": uid, "version": 1, "weekStart": ""}


PCT_TH = [{"color": "green", "value": None},
          {"color": "orange", "value": 70},
          {"color": "red", "value": 85}]
UPDOWN = [{"color": "red", "value": None}, {"color": "green", "value": 1}]

# ============ 1. PHAN CUNG VPS ============
cpu = '100 - (avg(rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)'
ram = '(1 - node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes) * 100'
FS = 'fstype!~"tmpfs|overlay|squashfs|ramfs",mountpoint!~"/(run|var/lib/docker|boot/efi).*"'
disk = ('(1 - min(node_filesystem_avail_bytes{%s} '
        '/ node_filesystem_size_bytes{%s})) * 100' % (FS, FS))

hw = [
    panel("CPU dang dung", "gauge", [(cpu, "CPU %")], 0, 0, 6, 6, "percent", PCT_TH,
          "Phan tram CPU cua VPS dang duoc su dung", 100),
    panel("RAM dang dung", "gauge", [(ram, "RAM %")], 6, 0, 6, 6, "percent", PCT_TH, "", 100),
    panel("O dia dang dung (phan vung day nhat)", "gauge", [(disk, "Disk %")], 12, 0, 6, 6, "percent", PCT_TH, "", 100),
    panel("Uptime VPS", "stat",
          [("node_time_seconds - node_boot_time_seconds", "uptime")], 18, 0, 6, 6, "s"),
    panel("CPU theo thoi gian (%)", "timeseries",
          [(cpu, "CPU tong"),
           ('avg(rate(node_cpu_seconds_total{mode="iowait"}[5m])) * 100', "IO wait")],
          0, 6, 12, 8, "percent"),
    panel("Bo nho (bytes)", "timeseries",
          [("node_memory_MemTotal_bytes", "Tong RAM"),
           ("node_memory_MemTotal_bytes - node_memory_MemAvailable_bytes", "Dang dung"),
           ("node_memory_SwapTotal_bytes - node_memory_SwapFree_bytes", "Swap dung")],
          12, 6, 12, 8, "bytes"),
    panel("Luu luong mang", "timeseries",
          [('sum(rate(node_network_receive_bytes_total{device!~"lo|veth.*|docker.*|br-.*"}[5m]))', "Nhan vao"),
           ('sum(rate(node_network_transmit_bytes_total{device!~"lo|veth.*|docker.*|br-.*"}[5m]))', "Gui ra")],
          0, 14, 12, 8, "Bps"),
    panel("Load average", "timeseries",
          [("node_load1", "1 phut"), ("node_load5", "5 phut"), ("node_load15", "15 phut")],
          12, 14, 12, 8),
    panel("Doc/ghi o dia", "timeseries",
          [("sum(rate(node_disk_read_bytes_total[5m]))", "Doc"),
           ("sum(rate(node_disk_written_bytes_total[5m]))", "Ghi")],
          0, 22, 24, 8, "Bps"),
]

# ============ 2. MONGODB ============
mg = [
    panel("MongoDB", "stat", [("mongodb_up", "up")], 0, 0, 6, 5, None, UPDOWN,
          "1 = database dang chay, 0 = down"),
    panel("Backend ket noi duoc DB", "stat", [("todo_mongodb_up", "connected")], 6, 0, 6, 5,
          None, UPDOWN, "Lay tu /metrics cua backend Express"),
    panel("Ket noi hien tai", "stat",
          [('mongodb_ss_connections{conn_type="current"}', "current")], 12, 0, 6, 5),
    panel("Uptime MongoDB", "stat", [("mongodb_ss_uptime", "uptime")], 18, 0, 6, 5, "s"),
    panel("Operations / giay", "timeseries",
          [("rate(mongodb_ss_opcounters[1m])", "{{legacy_op_type}}")], 0, 5, 12, 8, "ops"),
    panel("Ket noi (current / available)", "timeseries",
          [('mongodb_ss_connections{conn_type="current"}', "Dang mo"),
           ('mongodb_ss_connections{conn_type="available"}', "Con trong")], 12, 5, 12, 8),
    panel("Bo nho MongoDB", "timeseries",
          [("mongodb_ss_mem_resident * 1024 * 1024", "Resident"),
           ("mongodb_ss_mem_virtual * 1024 * 1024", "Virtual")], 0, 13, 12, 8, "bytes"),
    panel("Dung luong du lieu theo database", "timeseries",
          [("mongodb_dbstats_dataSize", "{{database}}")], 12, 13, 12, 8, "bytes"),
    panel("Document thao tac / giay", "timeseries",
          [("rate(mongodb_ss_metrics_document[1m])", "{{doc_op_type}}")], 0, 21, 12, 8, "ops"),
    panel("Cursor dang mo", "timeseries",
          [('mongodb_ss_metrics_cursor_open{csr_type="total"}', "Tong cursor")], 12, 21, 12, 8),
]

# ============ 3. UNG DUNG & CONTAINER ============
LAT_TH = [{"color": "green", "value": None},
          {"color": "orange", "value": 1},
          {"color": "red", "value": 2}]
app = [
    panel("Frontend", "stat",
          [('probe_success{instance="http://frontend:80/healthz"}', "frontend")], 0, 0, 6, 5,
          None, UPDOWN),
    panel("Backend API", "stat",
          [('probe_success{instance="http://backend:8000/health"}', "backend")], 6, 0, 6, 5,
          None, UPDOWN),
    panel("Request / giay", "stat",
          [("sum(rate(http_request_duration_seconds_count[5m]))", "rps")], 12, 0, 6, 5, "reqps"),
    panel("Do tre p95", "stat",
          [("histogram_quantile(0.95, sum by (le) (rate(http_request_duration_seconds_bucket[5m])))", "p95")],
          18, 0, 6, 5, "s", LAT_TH),
    panel("Luu luong API theo route", "timeseries",
          [("sum by (route) (rate(http_request_duration_seconds_count[5m]))", "{{route}}")],
          0, 5, 12, 8, "reqps"),
    panel("Do tre API (p50 / p95 / p99)", "timeseries",
          [("histogram_quantile(0.50, sum by (le) (rate(http_request_duration_seconds_bucket[5m])))", "p50"),
           ("histogram_quantile(0.95, sum by (le) (rate(http_request_duration_seconds_bucket[5m])))", "p95"),
           ("histogram_quantile(0.99, sum by (le) (rate(http_request_duration_seconds_bucket[5m])))", "p99")],
          12, 5, 12, 8, "s"),
    panel("Ma tra ve HTTP", "timeseries",
          [("sum by (status_code) (rate(http_request_duration_seconds_count[5m]))", "{{status_code}}")],
          0, 13, 12, 8, "reqps"),
    panel("Thoi gian phan hoi cua probe", "timeseries",
          [("probe_duration_seconds", "{{instance}}")], 12, 13, 12, 8, "s"),
    panel("CPU tung container", "timeseries",
          [('sum by (name) (rate(container_cpu_usage_seconds_total{name=~"todo-.+"}[5m])) * 100', "{{name}}")],
          0, 21, 12, 8, "percent"),
    panel("RAM tung container", "timeseries",
          [('sum by (name) (container_memory_working_set_bytes{name=~"todo-.+"})', "{{name}}")],
          12, 21, 12, 8, "bytes"),
    panel("Bo nho heap Node.js", "timeseries",
          [('nodejs_heap_size_used_bytes{app="todo-backend"}', "Heap dung"),
           ('nodejs_heap_size_total_bytes{app="todo-backend"}', "Heap cap phat"),
           ('process_resident_memory_bytes{app="todo-backend"}', "RSS")],
          0, 29, 12, 8, "bytes"),
    panel("Event loop lag (Node.js)", "timeseries",
          [('nodejs_eventloop_lag_p99_seconds{app="todo-backend"}', "lag p99")],
          12, 29, 12, 8, "s"),
]

os.makedirs(OUT, exist_ok=True)
files = {
    "01-vps-hardware.json": dashboard("todo-hardware", "01 - Phan cung VPS (CPU / RAM / Disk)",
                                      ["todo", "hardware"], hw,
                                      "Theo doi cau hinh & tai nguyen phan cung cua VPS"),
    "02-mongodb.json": dashboard("todo-mongodb", "02 - Trang thai Database MongoDB",
                                 ["todo", "database"], mg,
                                 "Theo doi trang thai, ket noi va hieu nang MongoDB"),
    "03-app-containers.json": dashboard("todo-app", "03 - Ung dung & Container",
                                        ["todo", "app"], app,
                                        "API, uptime endpoint va tai nguyen tung container"),
}
for name, d in files.items():
    with open(os.path.join(OUT, name), "w", encoding="utf-8") as f:
        json.dump(d, f, indent=2, ensure_ascii=False)
    print("wrote", name, "panels =", len(d["panels"]))
