# 🏨 Hotel World — Native Flutter Mobile Application (Android & iOS)

Ye document Hotel World Quotation System ke naye **Native Flutter Mobile App** ki poori architecture, calculations, setup aur APK installation guide explain karta hai.

---

## 🌟 1. Project Overview & Separation

- **Folder Path**: `c:\Hotelworld\Quotation_System\hotel_world_app`
- **Zero Website Impact**: Aapki existing website (`frontend`) aur backend (`backend`) ko **kisi bhi tareeqe se modify ya break nahi kiya gaya hai**. Flutter app ek independent alag folder me clean architecture ke sath create kiya gaya hai.
- **100% Real Live Sync**: App direct aapke live Render cloud backend (`https://hotelworld-backend.onrender.com`) aur Cloud MySQL database se connected hai. Jo bhi quotation ya product app se banega ya edit hoga, wo website par turant dikhega, aur website ka data app me real-time synchronized rahega!
- **Pure Native Flutter**: Koi WebView nahi hai, ye 100% pure Dart & Flutter native application hai with high-performance responsive UI for Android & iOS.

---

## 🛠️ 2. Environment Setup (Without Android Studio!)

Aapne kaha tha ki Android Studio nahi chahiye. Humne saare tools headless CLI ke through configure kar diye hain:

1. **Flutter SDK**: `3.50.0` (Channel stable, Dart `3.14.0`) at `D:\flutter_windows_3.50.0-stable\flutter\bin`
2. **Java JDK**: `Microsoft OpenJDK 17.0.21` at `C:\Program Files\Microsoft\jdk-17.0.21.21-hotspot` (Configured permanently in system `JAVA_HOME` & `Path`)
3. **Android SDK**: `Platform 36.0.0` & `Build-Tools 36.0.0 / 35.0.0` at `C:\Android\Sdk`
4. **Licenses**: All Android SDK licenses accepted automatically (`flutter doctor --android-licenses`).
5. **Flutter Doctor Status**:
   ```
   [√] Flutter (Channel stable, 3.50.0, on Microsoft Windows)
   [√] Windows Version (10 Pro 64-bit, 22H2)
   [√] Android toolchain - develop for Android devices (Android SDK version 36.0.0)
   [√] Chrome - develop for the web
   [√] Connected device (3 available)
   [√] Network resources
   ```

---

## 📱 3. Core Mobile Features & Screens

| Screen / Feature | Description |
|---|---|
| **Login Screen** | Hotel World Luxury Gold & Slate theme, role-based login (`ADMIN` / `STAFF`), quick demo autofill, backend connection status badge. |
| **Dashboard** | KPI statistics (Total Quotes, 7,941+ Products, Customers, Active Drafts), Quick Action buttons, Recent Quotations with 1-tap PDF & Edit. |
| **Quotation Engine** | 1:1 match with web `CreateQuotationPage.jsx`. Customer autofill/manual entry, Quote # generator, Date, Mode (Standard vs Machinery), Document Title (QUOTATION/ESTIMATE), Prepared By, Rate Given By. |
| **Items Management** | Add from 7,900+ real Catalog items, or Add Custom Line Items. Real-time Qty, Unit, Rate, GST% dropdown (0, 5, 12, 18, 28%), GST Included toggle (`isGstAdded`), Installation charges per item, Net & Gross calculations. |
| **Live Calculations** | Net Amount = Qty × Rate; GST Amount = Net × GST% / 100; Gross = Net + GST + Installation; Packing, Delivery, Previous charges (+ custom labels); Overall Discount; Grand Final Total. |
| **GST Mode Switcher** | 1-tap switch between `WITH_GST` (Calculate & add tax to final bill) and `WITHOUT_GST` (0% tax exempt quotation). |
| **PDF Invoice & Share** | Official Hotel World PDF generation with company header, logo, customer details box, items table, GST calculations, Terms & Conditions, Bank details, Signatory. **1-Tap Share to WhatsApp / Email** and **Direct WiFi / Bluetooth Printing**. |
| **Product Catalog** | Instant search across 7,941+ products with category chips, Cloudinary photos, add/edit product with camera/gallery photo upload, delete product. |
| **Pricing Rules Calculator** | Built-in interactive bottom-sheet calculator for **Rule 1 (Code-based)**, **Rule 2 (MRP-based)**, **Rule 3 (Company-based)**, and **Rule 4 (Custom formula)**. |
| **Customers Directory** | Full customer list, search, 1-tap Phone Call (`tel:`), 1-tap WhatsApp message, 1-tap "Create Quote for this Customer", Add/Edit customer modal. |
| **Company Settings** | Company profile, trade name, address, GSTIN, PAN, quote prefix, validity days, terms & conditions, and **Backend URL Switcher** (Render Cloud live vs Local network IP). |
| **Users & Permissions** | Admin-only staff account manager with permissions (`canViewPreviousQuotations`, `canManageCatalog`, activate/disable). |

---

## 📐 4. Exact Calculations & Pricing Formulas (1:1 Web Match)

### A. Quotation Item Row Math:
$$\text{Net Amount} = \text{Quantity} \times \text{Price}$$
$$\text{GST Amount} = \begin{cases} \dfrac{\text{Net Amount} \times \text{GST}\%}{100} & \text{if } \text{isGstAdded is true and } \text{GST}\% > 0 \\ 0 & \text{otherwise} \end{cases}$$
$$\text{Gross Amount} = \text{Net Amount} + \text{GST Amount} + \text{Installation Charge}$$

### B. Grand Total Math:
$$\text{Total Gross} = \sum \text{Gross Amount} + \text{Packing Charges} + \text{Delivery Charges} + \text{Previous Charges}$$
$$\text{Final Amount} = \max(0, \text{Total Gross} - \text{Overall Discount})$$

### C. Master Catalog Pricing Rules Engine:
- **Rule 1 (Code-Based)**:
  $$\text{Buying Price} = \text{ExtractCode}(\text{itemCode}) \times \text{Multiplier (default 30)}$$
  $$\text{Selling Price} = \text{Buying Price} \times (1 + \text{Margin}\% / 100)$$
- **Rule 2 (MRP-Based)**:
  $$\text{Buying Price} = \text{MRP} \times (1 - \text{BuyingDiscount}\% / 100)$$
  $$\text{Selling Price} = \text{MRP} \times (1 - \text{SellingDiscount}\% / 100)$$
- **Rule 3 (Company-Based)**:
  $$\text{Discounted Base} = \text{MRP} \times (1 - \text{CompanyDiscount}\% / 100)$$
  $$\text{With GST} = \text{Discounted Base} \times (1 + \text{GST}\% / 100)$$
  $$\text{Buying Price} = \text{With GST} \times (1 + \text{Freight}\% / 100)$$
  $$\text{Selling Price} = \text{Buying Price} \times (1 + \text{Margin}\% / 100)$$

---

## 🚀 5. How to Build & Install the APK on Any Android Device

### Option A: 1-Click Builder Script
Aapke folder me humne ek direct double-click file bana di hai:
👉 **`c:\Hotelworld\Quotation_System\hotel_world_app\BUILD_ANDROID_APK.bat`**

Bas is file par double-click karein:
1. Ye dependencies check karega.
2. Self-contained Release APK compile karega.
3. APK file yahan save hogi:
   `c:\Hotelworld\Quotation_System\hotel_world_app\build\app\outputs\flutter-apk\app-release.apk`

### Option B: Installing on Multiple Devices
1. `app-release.apk` file ko apne phone me send karein (WhatsApp Web, Google Drive, Bluetooth ya USB Cable se).
2. Phone me file par tap karein -> **Install**.
3. Agar phone puche "Install unknown apps", to "Allow" kardein.
4. App install ho jayega aur bina Play Store ke multiple devices par direct chalega!

---

## 🍎 6. iOS Compatibility

Project me standard iOS structure (`hotel_world_app/ios`) fully configured hai. Jab bhi aapko iPhone / iPad ke liye build karna ho:
1. Mac system par project open karein.
2. `cd hotel_world_app && flutter build ipa` run karein.

