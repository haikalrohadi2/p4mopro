
class Mahasiswa {
  final int? id;
  final String nama;
  final String nim;
  final String programStudi;

  const Mahasiswa({
    this.id,
    required this.nama,
    required this.nim,
    required this.programStudi,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nama': nama,
      'nim': nim,
      'program_studi': programStudi,
    };
  }

  factory Mahasiswa.fromMap(Map<String, dynamic> map) {
    return Mahasiswa(
      id: map['id'] as int,
      nama: map['nama'] as String,
      nim: map['nim'] as String,
      programStudi: map['program_studi'] as String,
    );
  }
}
