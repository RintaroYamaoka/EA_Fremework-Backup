from pathlib import Path

# Pathクラスインスタンス作成
SOURCE_DIR = Path(r"C:\Users\rintaroyamaoka\AppData\Roaming\MetaQuotes\Terminal\C4171FD2B38378D6406D5C84412B5F20\MQL5\Experts\MyEA")
DEST_DIR   = Path(r"C:\Users\rintaroyamaoka\Documents\MyProjects\MT5Projects\MyEA_BackupUTF-8")

# 対象拡張子
TARGET_EXTENSIONS = [".mq5", ".mqh"]


def convert_utf8(source: Path, dest: Path):

    for path in source.rglob("*"):    # 再帰的にすべてのファイル・フォルダを取得。

        if path.suffix.lower() in TARGET_EXTENSIONS:
            # 相対パスで保存先を作る
            output_path = dest / path.relative_to(source)
            output_path.parent.mkdir(parents = True, exist_ok = True)

            try:
                # UTF-16で読み込み
                content = path.read_text(encoding = "utf-16")
                # UTF-8で保存
                output_path.write_text(content, encoding = "utf-8")
                print(f"変換成功: {output_path}")

            except Exception as e:
                print(f"変換失敗: {path} → {e}")


# スプリクトを直接実行したときだけ動く
if __name__ == "__main__":
    convert_utf8(SOURCE_DIR, DEST_DIR)
