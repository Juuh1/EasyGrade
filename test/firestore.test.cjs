const { before, after, beforeEach, test } = require('node:test');
const { readFileSync } = require('node:fs');
const { initializeTestEnvironment, assertSucceeds, assertFails } = require('@firebase/rules-unit-testing');
const { doc, collection, setDoc, updateDoc, getDoc, getDocs, deleteDoc, serverTimestamp, Timestamp } = require('firebase/firestore');

let ambiente;
const completo = dados => ({ ...dados, versaoEsquema: 1,
  criadoEm: serverTimestamp(), atualizadoEm: serverTimestamp() });
const perfil = { nome: 'Professor A', email: 'professor-a@example.test',
  instituicao: '', reduzirMovimento: false };
const avaliacao = { nome: 'Avaliação', codigo: 'EG-1', disciplina: 'Matemática',
  turma: 'Turma A', data: null, numQuestoes: 3, numAlternativas: 4, status: 'rascunho' };
const professor = () => ambiente.authenticatedContext('professor-a',
  { email: perfil.email }).firestore();

before(async () => {
  ambiente = await initializeTestEnvironment({ projectId: 'demo-easygrade',
    firestore: { rules: readFileSync('firestore.rules', 'utf8') } });
});
beforeEach(async () => ambiente.clearFirestore());
after(async () => ambiente?.cleanup());

test('professor cria e consulta seu próprio perfil', async () => {
  const ref = doc(professor(), 'usuarios/professor-a');
  await assertSucceeds(setDoc(ref, completo(perfil)));
  await assertSucceeds(getDoc(ref));
});

test('acesso sem login é recusado', async () => {
  const db = ambiente.unauthenticatedContext().firestore();
  await assertFails(getDoc(doc(db, 'usuarios/professor-a')));
  await assertFails(setDoc(doc(db, 'usuarios/professor-a/turmas/t1'), completo({nome: 'A'})));
});

test('um professor não acessa os dados de outro', async () => {
  const db = ambiente.authenticatedContext('professor-b', {email: 'b@example.test'}).firestore();
  await assertFails(getDoc(doc(db, 'usuarios/professor-a')));
  await assertFails(getDocs(collection(db, 'usuarios/professor-a/avaliacoes')));
  await assertFails(setDoc(doc(db, 'usuarios/professor-a/turmas/t1'), completo({nome: 'A'})));
  await assertFails(deleteDoc(doc(db, 'usuarios/professor-a/avaliacoes/a1/correcoes/aluno1')));
});

test('perfil não aceita email de outra pessoa ou privilégios inventados', async () => {
  const ref = doc(professor(), 'usuarios/professor-a');
  await assertFails(setDoc(ref, completo({...perfil, email: 'outro@example.test'})));
  await assertFails(setDoc(ref, completo({...perfil, admin: true})));
  await assertFails(setDoc(ref, completo({...perfil, role: 'admin'})));
});

test('turma permite cadastrar, listar, editar e excluir', async () => {
  const db = professor(), ref = doc(db, 'usuarios/professor-a/turmas/t1');
  await assertSucceeds(setDoc(ref, completo({nome: 'Turma A'})));
  await assertSucceeds(getDocs(collection(db, 'usuarios/professor-a/turmas')));
  await assertSucceeds(updateDoc(ref, {nome: 'Turma B', atualizadoEm: serverTimestamp()}));
  await assertSucceeds(deleteDoc(ref));
});

test('documento mantém data de criação e usa atualização do servidor', async () => {
  const ref = doc(professor(), 'usuarios/professor-a/turmas/t1');
  await assertSucceeds(setDoc(ref, completo({nome: 'A'})));
  await assertFails(updateDoc(ref, {criadoEm: Timestamp.fromMillis(0), atualizadoEm: serverTimestamp()}));
  await assertFails(updateDoc(ref, {nome: 'B', atualizadoEm: Timestamp.fromMillis(0)}));
  await assertFails(updateDoc(ref, {versaoEsquema: 99, atualizadoEm: serverTimestamp()}));
});

test('coleções não previstas e documentos sem metadados são recusados', async () => {
  const db = professor();
  await assertFails(setDoc(doc(db, 'usuarios/professor-a/admin/a'), completo({nome: 'A'})));
  await assertFails(setDoc(doc(db, 'usuarios/professor-a/turmas/t1'), {nome: 'A'}));
  await assertFails(setDoc(doc(db, 'usuarios/professor-a/turmas/t1'), completo({nome: ''})));
});

test('questões validam a quantidade de alternativas e a resposta correta', async () => {
  const ref = doc(professor(), 'usuarios/professor-a/questoes/q1');
  const questao = {enunciado: 'Quanto é 1 + 1?', disciplina: 'Matemática',
    alternativas: ['1', '2', '3'], correta: 1};
  await assertSucceeds(setDoc(ref, completo(questao)));
  await assertFails(updateDoc(ref, {correta: 9, atualizadoEm: serverTimestamp()}));
  await assertFails(updateDoc(ref, {alternativas: ['1'], atualizadoEm: serverTimestamp()}));
});

test('avaliações validam status e limites do formato atual', async () => {
  const ref = doc(professor(), 'usuarios/professor-a/avaliacoes/a1');
  await assertSucceeds(setDoc(ref, completo(avaliacao)));
  await assertFails(updateDoc(ref, {status: 'publica', atualizadoEm: serverTimestamp()}));
  await assertFails(updateDoc(ref, {numQuestoes: 61, atualizadoEm: serverTimestamp()}));
  await assertFails(updateDoc(ref, {numAlternativas: 1, atualizadoEm: serverTimestamp()}));
});

test('gabarito precisa da avaliação e respeita seu número de alternativas', async () => {
  const db = professor(), ref = doc(db, 'usuarios/professor-a/avaliacoes/a1/gabaritos/A');
  await assertFails(setDoc(ref, completo({respostas: [0, 1, 2]})));
  await assertSucceeds(setDoc(doc(db, 'usuarios/professor-a/avaliacoes/a1'), completo(avaliacao)));
  await assertFails(setDoc(ref, completo({respostas: [0, 1]})));
  await assertFails(setDoc(ref, completo({respostas: [0, 1, 4]})));
  await assertFails(setDoc(ref, completo({respostas: [0, 1, 'C']})));
  await assertSucceeds(setDoc(ref, completo({respostas: [0, 1, 2]})));
});

test('correções preservam respostas em branco, múltiplas e incertas', async () => {
  const db = professor();
  await setDoc(doc(db, 'usuarios/professor-a/avaliacoes/a1'), completo(avaliacao));
  const ref = doc(db, 'usuarios/professor-a/avaliacoes/a1/correcoes/aluno1');
  await assertSucceeds(setDoc(ref, completo({alunoId: 'aluno1', alunoNome: 'Aluno',
    variante: 'A', lidaEm: Timestamp.now(), respostas: [null, -1, -2]})));
  await assertFails(updateDoc(ref, {respostas: [0, 1, 9], atualizadoEm: serverTimestamp()}));
  await assertSucceeds(updateDoc(ref, {respostas: [0, 1, 2], atualizadoEm: serverTimestamp()}));
});

test('aluno de turma exige uma turma existente', async () => {
  const db = professor(), ref = doc(db, 'usuarios/professor-a/turmas/t1/alunos/aluno1');
  await assertFails(setDoc(ref, completo({nome: 'Aluno'})));
  await setDoc(doc(db, 'usuarios/professor-a/turmas/t1'), completo({nome: 'Turma A'}));
  await assertSucceeds(setDoc(ref, completo({nome: 'Aluno'})));
});
