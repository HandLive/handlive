# Prompt khởi động session sau (HandLive)

Dán nguyên khối dưới vào một session mới.

```text
Tiếp tục dự án HandLive (workspace 5 repo: hub ~/HandLive + android/ apple/ shared/ relay/).
Nói chuyện với tôi bằng tiếng Việt có dấu.

ĐỌC TRƯỚC: ./CLAUDE.md, rồi plans/20260925-implementation/reports/session-2026-10-03-app-calls-and-ci.md
(handoff mới nhất: đã làm + việc tiếp theo), và docs/detailed-design/README.md khi cần.

TRẠNG THÁI (mọi thứ đã trên main): hub 89bc30f, shared af3629f, android f57b291, apple a752c67, relay cda13bf.
CALL-05 (cuộc gọi app khác trên Mac) đã xong, test thật S25↔Mac, âm thanh v1 ở điện thoại. Apple CI đã xanh.
Chạy tools/workspace.sh status để xác nhận trước khi code.

LÀM TIẾP (ưu tiên trên xuống):
1. Phase 7 "Kết nối mọi nơi": quyết lịch (đang là đề xuất, sau gate G4/G5/G6) và cập nhật README roadmap cho CALL-05.
2. T3.3 cho CALL-05 còn thiếu: máy CÓ SIM để kiểm loại trừ cuộc gọi di động; tap-to-answer (tắt Accessibility);
   màn hình tắt/khóa; đường relay; Zalo/WhatsApp. Thêm hỗ trợ app_call_* vào shared/tools/bench/call_latency.py.
3. Follow-up CALL-05 (từ review): L4 (vuốt bỏ thông báo đang gọi làm kết thúc sớm), L12 (nhãn app ra tên gói —
   cần <queries>, kiểm "Telegram" hiển thị đúng).
4. Lỗi pair-store của Mac (khóa cũ sau khi đổi build → ghép đôi một phía): land fix (đã có task riêng).
5. Test timing HLAppCore đang chạy serial trong CI như giải pháp tạm; cân nhắc virtual-clock để chạy song song lại.
   PairingSearch.run còn 1 swiftlint:disable cyclomatic_complexity.
6. Các gate còn mở: G1 (ma trận thiết bị + a11y), G2 (Play Console), G4 (âm thanh cuộc gọi — HFP/Shizuku đều no-go
   trên OS hiện tại), G5 (camera/mic, cần Apple Developer trả phí), G6 (go/no-go trình duyệt).

RÀNG BUỘC: commit danh tính Hồ Xuân Dũng <me@hxd.vn> kèm git commit -s, không dòng AI/Co-authored, không email
Viettel; shared trước khi đổi contract rồi chạy tay CI nền tảng; mỗi commit một repo; KHÔNG tự merge vào main
(tôi tự chạy FF-push) và KHÔNG tự push nếu chưa được bảo.

Bắt đầu bằng: tóm tắt trạng thái từ handoff + hỏi tôi chọn việc nào trong danh sách trên.
```
