#include <Rcpp.h>
#include <fstream>
#include <string>
#include <sstream>

#ifdef _WIN32
#include <windows.h>
#include <psapi.h>
#else
#include <unistd.h>
#include <sys/resource.h>
#endif

using namespace Rcpp;

//' Get RAM Usage (Fast C++ Implementation)
//'
//' Fast implementation to get current RAM usage in MB.
//'
//' @return Numeric value representing RAM usage in MB
//' @keywords internal
// [[Rcpp::export]]
double get_ram_usage_cpp() {
#ifdef _WIN32
  // Windows implementation
  PROCESS_MEMORY_COUNTERS_EX pmc;
  if (GetProcessMemoryInfo(GetCurrentProcess(), (PROCESS_MEMORY_COUNTERS*)&pmc, sizeof(pmc))) {
    SIZE_T virtualMemUsed = pmc.PrivateUsage;
    return virtualMemUsed / (1024.0 * 1024.0);  // Convert to MB
  }
  return 0.0;
#else
  // Linux/Unix implementation
  std::ifstream status_file("/proc/self/status");
  if (!status_file.is_open()) {
    // Fallback to getrusage
    struct rusage usage;
    getrusage(RUSAGE_SELF, &usage);
#ifdef __APPLE__
    return usage.ru_maxrss / (1024.0 * 1024.0);  // macOS reports in bytes
#else
    return usage.ru_maxrss / 1024.0;  // Linux reports in KB
#endif
  }

  std::string line;
  double rss_mb = 0.0;

  while (std::getline(status_file, line)) {
    if (line.substr(0, 6) == "VmRSS:") {
      std::istringstream iss(line.substr(6));
      double rss_kb;
      iss >> rss_kb;
      rss_mb = rss_kb / 1024.0;
      break;
    }
  }
  status_file.close();
  return rss_mb;
#endif
}

//' Fast Chunk Splitting
//'
//' Efficiently splits a numeric vector into chunks.
//'
//' @param x Numeric vector to chunk
//' @param chunk_size Size of each chunk
//' @return List of numeric vectors (chunks)
//' @keywords internal
// [[Rcpp::export]]
List split_vector_chunks(NumericVector x, int chunk_size) {
  int n = x.size();
  int num_chunks = (n + chunk_size - 1) / chunk_size;
  List result(num_chunks);

  for (int i = 0; i < num_chunks; i++) {
    int start = i * chunk_size;
    int end = std::min(start + chunk_size, n);
    int chunk_len = end - start;

    NumericVector chunk(chunk_len);
    for (int j = 0; j < chunk_len; j++) {
      chunk[j] = x[start + j];
    }
    result[i] = chunk;
  }

  return result;
}

//' Fast Chunk Splitting for Matrices
//'
//' Efficiently splits a matrix into row-wise chunks.
//'
//' @param mat Numeric matrix to chunk
//' @param chunk_size Number of rows per chunk
//' @return List of numeric matrices (chunks)
//' @keywords internal
// [[Rcpp::export]]
List split_matrix_chunks(NumericMatrix mat, int chunk_size) {
  int nrows = mat.nrow();
  int ncols = mat.ncol();
  int num_chunks = (nrows + chunk_size - 1) / chunk_size;
  List result(num_chunks);

  for (int i = 0; i < num_chunks; i++) {
    int start = i * chunk_size;
    int end = std::min(start + chunk_size, nrows);
    int chunk_rows = end - start;

    NumericMatrix chunk(chunk_rows, ncols);
    for (int r = 0; r < chunk_rows; r++) {
      for (int c = 0; c < ncols; c++) {
        chunk(r, c) = mat(start + r, c);
      }
    }
    result[i] = chunk;
  }

  return result;
}

//' Calculate Optimal Chunk Size
//'
//' Calculates optimal chunk size based on data size and RAM limits.
//'
//' @param data_size_mb Size of data in MB
//' @param total_rows Total number of rows
//' @param max_ram_mb Maximum RAM in MB
//' @param target_fraction Fraction of max RAM to use per chunk (default 0.1)
//' @return Optimal chunk size (number of rows)
//' @keywords internal
// [[Rcpp::export]]
int calculate_optimal_chunk_size(double data_size_mb,
                                 int total_rows,
                                 double max_ram_mb,
                                 double target_fraction = 0.1) {
  double target_chunk_ram = max_ram_mb * target_fraction;
  int chunk_size = static_cast<int>(std::floor(total_rows * target_chunk_ram / data_size_mb));

  // Ensure minimum chunk size of 1
  if (chunk_size < 1) chunk_size = 1;

  // Cap at total rows
  if (chunk_size > total_rows) chunk_size = total_rows;

  return chunk_size;
}

//' Monitor RAM During Processing
//'
//' Monitors RAM usage and returns true if threshold is exceeded.
//'
//' @param max_ram_mb Maximum RAM threshold in MB
//' @return Boolean indicating if RAM threshold is exceeded
//' @keywords internal
// [[Rcpp::export]]
bool ram_threshold_exceeded(double max_ram_mb) {
  double current_ram = get_ram_usage_cpp();
  return current_ram > max_ram_mb;
}

//' Get System Information
//'
//' Returns system information including total and available RAM.
//'
//' @return List with system memory information
//' @keywords internal
// [[Rcpp::export]]
List get_system_info() {
#ifdef _WIN32
  MEMORYSTATUSEX memInfo;
  memInfo.dwLength = sizeof(MEMORYSTATUSEX);
  GlobalMemoryStatusEx(&memInfo);

  return List::create(
    Named("total_ram_mb") = memInfo.ullTotalPhys / (1024.0 * 1024.0),
    Named("available_ram_mb") = memInfo.ullAvailPhys / (1024.0 * 1024.0),
    Named("used_ram_mb") = get_ram_usage_cpp()
  );
#else
  // Unix/Linux implementation
  long pages = sysconf(_SC_PHYS_PAGES);
  long page_size = sysconf(_SC_PAGE_SIZE);
  double total_ram_mb = (pages * page_size) / (1024.0 * 1024.0);

  long avail_pages = sysconf(_SC_AVPHYS_PAGES);
  double avail_ram_mb = (avail_pages * page_size) / (1024.0 * 1024.0);

  return List::create(
    Named("total_ram_mb") = total_ram_mb,
    Named("available_ram_mb") = avail_ram_mb,
    Named("used_ram_mb") = get_ram_usage_cpp()
  );
#endif
}
