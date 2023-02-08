import Cocoa

public class PDFPagePicker: NSViewController {
    public init() {
        super.init(nibName: "PDFPagePicker", bundle: Bundle.module)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
