#include <archive.h>
#include <archive_entry.h>

#include <iostream>
#include <string>
#include <chrono>
#include <filesystem>

namespace fs = std::filesystem;

bool extract(const std::string& archive_path, const std::string& output_dir) {
    struct archive* a = archive_read_new();
    struct archive* ext = archive_write_disk_new();
    struct archive_entry* entry;
    int r;

    if (!a || !ext) {
        std::cerr << "❌ Failed to create archive structures." << std::endl;
        return false;
    }

    archive_read_support_format_all(a);
    archive_read_support_filter_all(a);

    if ((r = archive_read_open_filename(a, archive_path.c_str(), 10240))) {
        std::cerr << "❌ Could not open archive: " << archive_error_string(a) << std::endl;
        archive_read_free(a);
        archive_write_free(ext);
        return false;
    }

    // 确保输出目录存在
    if (!fs::exists(output_dir)) {
        fs::create_directories(output_dir);
    }

    bool success = true;

    while (archive_read_next_header(a, &entry) == ARCHIVE_OK) {
        std::string full_path = output_dir + "/" + archive_entry_pathname(entry);
        archive_entry_set_pathname(entry, full_path.c_str());

        r = archive_write_header(ext, entry);
        if (r != ARCHIVE_OK) {
            std::cerr << "⚠️ Could not write header: " << archive_error_string(ext) << std::endl;
            success = false;
        } else {
            const void* buff;
            size_t size;
            la_int64_t offset;

            while (archive_read_data_block(a, &buff, &size, &offset) == ARCHIVE_OK) {
                archive_write_data(ext, buff, size);
            }
        }
        archive_write_finish_entry(ext);
    }

    archive_read_close(a);
    archive_read_free(a);
    archive_write_close(ext);
    archive_write_free(ext);

    return success;
}

int main(int argc, char *argv[]) {
    if (argc != 3) {
        std::cerr << "Usage: " << argv[0] << " <archive_file> <output_dir>\n";
        return 1;
    }

    std::string archivePath = argv[1];
    std::string outputPath = argv[2];

    auto start = std::chrono::steady_clock::now();

    bool result = extract(archivePath, outputPath);

    auto end = std::chrono::steady_clock::now();
    auto duration = std::chrono::duration_cast<std::chrono::milliseconds>(end - start).count();

    if (result) {
        std::cout << "✅ Extraction complete in " << duration << " ms." << std::endl;
        return 0;
    } else {
        std::cerr << "❌ Extraction failed after " << duration << " ms." << std::endl;
        return 1;
    }
}
