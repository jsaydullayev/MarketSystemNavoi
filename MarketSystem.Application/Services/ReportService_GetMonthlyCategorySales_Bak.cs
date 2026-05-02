// GetMonthlyCategorySalesAsync method - backup variant (tashqi mahsulotlar uchun "Boshqa" category)

// Agar tashqi mahsulotlar uchun alohida category yaratish talab qilsa, quyidagi variantni ishlating:
// Tashqi mahsulotlar uchun "Boshqa" (Other) categoryga joylashadi, oddiy categorylarga ta'sirilmaydi

// Hozirgi amal (Variant 3):
// - Oddiy mahsulotlar uchun ProductId bo'yicha guruhlash va category ichida saqlash
// - Tashqi mahsulotlar uchun alohida saqlash (ProductName), oddiy categorylarga ta'sirilmaydi

// Muammo: Tashqi mahsulotlarning categoryId yo'q (tashqi mahsulot), shuning uchun
// - "Boshqa" (Other) categoryga joylashish oddiy categorylarga ta'sirishiga sabab bo'lishi mumkin

// Yechim: CategorySalesDto qatori (key: categoryId) o'zgartish kerak bo'lishi mumkin,
// shunda tashqi mahsulotlarni oddiy categoryId ga jo'yish mumkin bo'ladi.
